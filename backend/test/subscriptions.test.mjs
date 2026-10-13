import test from "node:test";
import assert from "node:assert/strict";
import { APP_APPLE_ID, BUNDLE_ID, MONTHLY_PRODUCT_ID, configureAppleSubscriptions, createSubscriptionVerifier } from "../apple-subscriptions.mjs";

const now = 2_000_000;
const transaction = {
  bundleId: BUNDLE_ID, productId: MONTHLY_PRODUCT_ID,
  originalTransactionId: "original", type: "Auto-Renewable Subscription", expiresDate: now + 1000
};
function verifierFor({ status = 1, latest = transaction, proof = transaction, renewal, unavailable = false } = {}) {
  return createSubscriptionVerifier([{
    environment: "Sandbox",
    verifier: {
      async verifyAndDecodeTransaction(signed) {
        if (signed === "proof") return proof;
        if (signed === "latest") return latest;
        throw new Error("bad signature");
      },
      async verifyAndDecodeRenewalInfo() { return renewal; }
    },
    client: { async getAllSubscriptionStatuses(id) {
      assert.equal(id, "original");
      if (unavailable) throw new Error("offline");
      return { bundleId: BUNDLE_ID, environment: "Sandbox", data: [{ lastTransactions: [{
        originalTransactionId: "original", status, signedTransactionInfo: "latest", signedRenewalInfo: "renewal"
      }] }] };
    } }
  }], { now: () => now });
}

test("active Apple subscription grants access, including canceled-but-unexpired renewal", async () => {
  assert.deepEqual(await verifierFor()("proof"), { originalTransactionId: "original", environment: "Sandbox", expiresAt: now + 1000 });
});
test("cannot bypass verification with fabricated proof", async () => {
  await assert.rejects(verifierFor()("forged"), { status: 401 });
});
test("wrong app or product does not unlock Pro", async () => {
  await assert.rejects(verifierFor({ proof: { ...transaction, productId: "other" } })("proof"), { status: 403 });
  await assert.rejects(verifierFor({ proof: { ...transaction, bundleId: "other" } })("proof"), { status: 403 });
});
test("an old valid proof cannot override Apple's latest expired/revoked/billing-retry status", async () => {
  for (const status of [2, 3, 5]) await assert.rejects(verifierFor({ status })("proof"), { status: 403 });
});
test("expired or refunded latest transaction does not grant access even with active status", async () => {
  await assert.rejects(verifierFor({ latest: { ...transaction, expiresDate: now } })("proof"), { status: 403 });
  await assert.rejects(verifierFor({ latest: { ...transaction, revocationDate: now - 1 } })("proof"), { status: 403 });
  await assert.rejects(verifierFor({ latest: { ...transaction, originalTransactionId: "different" } })("proof"), { status: 403 });
});
test("verified billing grace period grants access only through grace expiry", async () => {
  const grace = { originalTransactionId: "original", productId: MONTHLY_PRODUCT_ID, gracePeriodExpiresDate: now + 100 };
  assert.equal((await verifierFor({ status: 4, latest: { ...transaction, expiresDate: now - 1 }, renewal: grace })("proof")).expiresAt, grace.gracePeriodExpiresDate);
  await assert.rejects(verifierFor({ status: 4, renewal: { ...grace, gracePeriodExpiresDate: now } })("proof"), { status: 403 });
});
test("Apple outages and missing configuration fail closed", async () => {
  await assert.rejects(verifierFor({ unavailable: true })("proof"), { status: 503 });
  const config = configureAppleSubscriptions({});
  assert.equal(config.ready, false);
  await assert.rejects(config.verify("proof"), { status: 503 });
  assert.equal(APP_APPLE_ID, 6801613425);
});

test("official Apple library rejects unsigned fabricated transactions before API use", async () => {
  const { SignedDataVerifier, Environment } = await import("@apple/app-store-server-library");
  const verifier = new SignedDataVerifier([], true, Environment.SANDBOX, BUNDLE_ID, APP_APPLE_ID);
  const header = Buffer.from(JSON.stringify({ alg: "none" })).toString("base64url");
  const payload = Buffer.from(JSON.stringify(transaction)).toString("base64url");
  await assert.rejects(verifier.verifyAndDecodeTransaction(`${header}.${payload}.`));
});
