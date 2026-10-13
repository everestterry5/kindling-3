import { readFileSync } from "node:fs";
import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from "@apple/app-store-server-library";

export const MONTHLY_PRODUCT_ID = "app.kindling.kindling3.pro.monthly";
export const BUNDLE_ID = "Kindling.app.kindling-3";
export const APP_APPLE_ID = 6801613425;
const failure = (status, message) => Object.assign(new Error(message), { status });

// The caller supplies Apple-verifying adapters; the production factory below uses
// Apple's official library, with certificate revocation checks enabled.
export function createSubscriptionVerifier(connections, { now = Date.now } = {}) {
  return async function verifySubscription(signedTransaction) {
    if (!connections.length) throw failure(503, "Subscription verification is temporarily unavailable. Please try again later.");
    let connection;
    let proof;
    for (const candidate of connections) {
      try {
        proof = await candidate.verifier.verifyAndDecodeTransaction(signedTransaction);
        connection = candidate;
        break;
      } catch { /* Never trust an unverified payload to choose an environment. */ }
    }
    if (!connection) throw failure(401, "Apple could not verify your subscription. Restore Purchases and try again.");
    if (proof.bundleId !== BUNDLE_ID || proof.productId !== MONTHLY_PRODUCT_ID ||
        !proof.originalTransactionId || proof.type !== "Auto-Renewable Subscription") {
      throw failure(403, "This purchase does not provide Kindling Pro access.");
    }

    let statuses;
    try {
      // Query Apple for the latest state on every paid AI call. An old signed
      // transaction alone must not grant access after a refund or expiration.
      statuses = await connection.client.getAllSubscriptionStatuses(proof.originalTransactionId);
    } catch {
      throw failure(503, "Apple subscription status could not be checked. Please try again shortly.");
    }
    if (statuses.bundleId !== BUNDLE_ID || statuses.environment !== connection.environment) {
      throw failure(503, "Apple returned an unexpected subscription status.");
    }
    for (const group of statuses.data ?? []) {
      for (const item of group.lastTransactions ?? []) {
        if (item.originalTransactionId !== proof.originalTransactionId || ![1, 4].includes(item.status)) continue;
        let transaction;
        try { transaction = await connection.verifier.verifyAndDecodeTransaction(item.signedTransactionInfo); }
        catch { throw failure(503, "Apple subscription status could not be verified. Please try again shortly."); }
        if (transaction.bundleId !== BUNDLE_ID || transaction.productId !== MONTHLY_PRODUCT_ID ||
            transaction.originalTransactionId !== proof.originalTransactionId || transaction.revocationDate != null ||
            transaction.isUpgraded || transaction.type !== "Auto-Renewable Subscription") continue;

        if (item.status === 1 && transaction.expiresDate > now()) {
          return { originalTransactionId: proof.originalTransactionId, environment: connection.environment, expiresAt: transaction.expiresDate };
        }
        if (item.status === 4 && item.signedRenewalInfo) {
          let renewal;
          try { renewal = await connection.verifier.verifyAndDecodeRenewalInfo(item.signedRenewalInfo); }
          catch { throw failure(503, "Apple subscription renewal could not be verified. Please try again shortly."); }
          if (renewal.originalTransactionId === proof.originalTransactionId && renewal.productId === MONTHLY_PRODUCT_ID &&
              renewal.gracePeriodExpiresDate > now()) {
            return { originalTransactionId: proof.originalTransactionId, environment: connection.environment, expiresAt: renewal.gracePeriodExpiresDate };
          }
        }
      }
    }
    throw failure(403, "Kindling Pro is no longer active. Check your subscription or restore purchases.");
  };
}

export function configureAppleSubscriptions(env = process.env) {
  const required = ["APPLE_IAP_KEY_PATH", "APPLE_KEY_ID", "APPLE_ISSUER_ID", "APPLE_ROOT_CA_PATHS"];
  if (required.some((key) => !env[key])) return { ready: false, verify: createSubscriptionVerifier([]) };
  const names = (env.APPLE_ENVIRONMENTS ?? "Production,Sandbox").split(",").map((value) => value.trim());
  if (!names.length || names.some((name) => ![Environment.PRODUCTION, Environment.SANDBOX].includes(name))) {
    throw new Error("APPLE_ENVIRONMENTS may contain only Production and Sandbox.");
  }
  const roots = env.APPLE_ROOT_CA_PATHS.split(",").map((path) => readFileSync(path.trim()));
  const key = readFileSync(env.APPLE_IAP_KEY_PATH, "utf8");
  const connections = [...new Set(names)].map((environment) => ({
    environment,
    verifier: new SignedDataVerifier(roots, true, environment, BUNDLE_ID, APP_APPLE_ID),
    client: new AppStoreServerAPIClient(key, env.APPLE_KEY_ID, env.APPLE_ISSUER_ID, BUNDLE_ID, environment)
  }));
  return { ready: true, verify: createSubscriptionVerifier(connections) };
}
