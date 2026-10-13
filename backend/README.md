# Kindling AI and App Store subscription backend

This release candidate keeps the OpenAI API key on the server, preserves the three-request free AI allowance, and verifies paid access with Apple's official App Store Server library. It is not deployed. No live purchase or paid API call was made during preparation.

## Run locally

Requires Node 20.6+ and pnpm 11.19.0. From this folder:

```sh
pnpm install --frozen-lockfile --ignore-scripts
cp .env.example .env
# Supply your own keys and file paths in .env; never commit it.
node --env-file=.env server.mjs
```

The server binds to `127.0.0.1:8787` by default. `GET /health` returns `ok`, `aiReady`, and `subscriptionsReady`. A running HTTP service is not proof that external Apple/OpenAI credentials work. The simulator's Debug configuration uses localhost; use an HTTPS host for a real iPhone and Release builds.

Run `pnpm test` for offline tests. They use mocked Apple/OpenAI responses and ephemeral loopback HTTP ports; no API spend or purchases. A local StoreKit configuration file creates Xcode-signed transactions, which this backend intentionally rejects. End-to-end purchase testing requires Apple sandbox/TestFlight transactions.

## Required App Store setup

- App Apple ID: `6801613425`.
- Bundle identifier: `Kindling.app.kindling-3` (case-sensitive; must match signed app).
- Subscription group: existing Monthly (`22355207`).
- Product: `app.kindling.kindling3.pro.monthly`, auto-renewable, one month.
- Suggested display name: **Kindling Pro Monthly**.
- Suggested description: **Unlimited Kindling AI coaching for your saved ideas.**
- Price, countries, and launch timing are owner decisions, not selected by this code.
- Complete the Paid Apps agreement, banking, and tax steps in App Store Connect.
- Keep Family Sharing and multiseat purchases off; the app has no seat management.
- Add subscription review screenshot and submit the first subscription with the reviewed app version after owner approval.

In App Store Connect, an Admin creates an **In-App Purchase** key under Users and Access → Integrations → In-App Purchase. Install its private `.p8` file as a server secret and set `APPLE_IAP_KEY_PATH`, `APPLE_KEY_ID`, and `APPLE_ISSUER_ID`. Download trusted DER root certificates from [Apple PKI](https://www.apple.com/certificateauthority/) and set `APPLE_ROOT_CA_PATHS` to their comma-separated local paths. Do not substitute a client-provided certificate or private key.

`APPLE_ENVIRONMENTS=Production,Sandbox` supports public App Store purchases as well as App Review/TestFlight. The server verifies the signature with the configured environment's verifier; it never uses unverified payloads as entitlement evidence. Xcode/LocalTesting environments are not accepted.

## Verification and payment behavior

The app sends the App Store JWS from a verified current StoreKit entitlement with each paid request. The backend verifies it with Apple's library and online certificate checks, then calls Get All Subscription Statuses for the original transaction. It verifies Apple's latest transaction and grants access only for the configured product, correct app, active and unexpired status, or a verified unexpired billing grace period. Refunded/revoked/expired/billing-retry subscriptions fail closed. Turning off auto-renew does not immediately cancel access before the paid expiration date. Missing keys and Apple outages never silently grant Pro access.

The app refreshes entitlement state on foreground, transaction updates, restore, purchase, and before sending an AI prompt. Local StoreKit grace-period entitlement is preserved. Restore remains available when new purchases are disabled. The backend independently enforces paid requests even if someone modifies the client.

New purchases require `/health` → `subscriptionsReady: true`. This requires OpenAI configuration, persistent quota storage, Apple verifier configuration, and `PRO_PURCHASES_ENABLED=true`. Leave that switch **false** until you finish sandbox verification. The health flag is an operator-controlled availability signal, not a live credential test.

## Hosting and cost controls

Deploy one process on an HTTPS Node host with persistent storage. Set `NODE_ENV=production`, `HOST=0.0.0.0`, and `QUOTA_FILE` to the persistent volume path. Production without `QUOTA_FILE` does not serve AI or enable purchases. Set the Xcode Release `KINDLING_API_BASE_URL` to that HTTPS origin, rebuild, and upload a new build. The old uploaded TestFlight build does not send subscription proof and cannot unlock paid requests on this server.

The `Dockerfile` installs the pinned official Apple library using the lockfile and runs as an unprivileged user. Mount writable persistent storage at `/data` and read-only secrets/certificates at separate paths. The image does not include keys or local quota data. Docker image creation itself has not been run in this environment.

Set `OPENAI_API_KEY` in host secrets. The existing `gpt-5.6-luna` default is documented to support Responses, web search, and structured outputs; account access still needs a real smoke test. Set an OpenAI project budget/alerts. Limits default to 20 requests per 10 minutes per socket IP and per paid original transaction, and 120 globally. These are temporary availability/abuse limits, not a monthly Pro allowance. Configure an edge limiter that identifies actual client IPs; the app ignores user-controlled `X-Forwarded-For`. Behind a reverse proxy, the app's socket-IP limit may cover all customers, so tune edge and server limits together before launch.

Free allowance is persisted by SHA256 of the installation ID. A successful free request uses one allowance; known upstream failure returns it. An in-flight crash may conservatively consume that request. The file store is capped at 100,000 installation records and fails closed when full. Back up and monitor it. Do not run multiple writers/instances; migrate to an atomic shared database before scaling.

**Remaining abuse limitation:** anonymous installation IDs can be reset or forged. The persistent allowance is an installation allowance, not authenticated person/device identity. Before a broad launch, add App Attest or an authenticated account/session scheme and shared edge limits, or explicitly accept and budget the limited anonymous traffic. This implementation does not claim to solve device attestation, theft of bearer purchase proof, or distributed denial of service.

## Data handling

No prompts, responses, transaction proofs, raw client IDs, or IPs are written to backend application logs. Logs contain only generic event text and status codes. OpenAI receives selected idea context, the last 12 messages, and the hashed installation safety identifier with `store:false`; transaction proof is not sent to OpenAI. `store:false` is not a promise about all provider retention. Review provider terms/settings and host access logs.

The quota file retains hashed installation IDs and free-use counts until the operator deletes them. Hashed socket-IP and transaction identifiers remain in process memory for rate limiting; expired entries are removed on the next limiter request or process exit. Signed purchase proof and current subscription status for interactive AI requests are processed transiently. Opt-in daily monitoring has separate protected persistence described below. Privacy disclosures and support/deletion procedures must reflect the final host and operator retention policy.

## Required real-device release checks

With the actual App Store product, approved price, keys, and HTTPS staging service configured:

1. Verify three free successful requests, server denial of a fourth, and no charge for a failed response.
2. In Apple sandbox, buy Pro and send a fourth AI request; confirm server checks the Apple transaction.
3. Cancel purchase, exercise pending/Ask to Buy if available, restore on a second device, and reopen/foreground the app.
4. Test sandbox renewal, expired subscription, refund/revocation, and billing grace period. Canceling renewal alone must keep access until expiration.
5. Disable Apple/OpenAI access and verify errors, no entitlement bypass, and no free-use deduction for upstream failure.
6. Check actual localized price, renewal terms, privacy and terms links, reviewer notes, then allow purchases with the operator switch.
7. Rebuild TestFlight and repeat on a real iPhone before any App Review submission/publication. Owner consent is still required to publish.

## Primary sources checked

- [Apple official App Store Server library](https://github.com/apple/app-store-server-library-node)
- [SignedDataVerifier](https://apple.github.io/app-store-server-library-node/classes/SignedDataVerifier.html)
- [Get All Subscription Statuses](https://developer.apple.com/documentation/appstoreserverapi/get_all_subscription_statuses)
- [StoreKit currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements)
- [OpenAI GPT-5.6 Luna API model](https://developers.openai.com/api/docs/models/gpt-5.6-luna)

## DeepSeek idea reports (October 12 follow-up)

`POST /v1/ideas/analyze` now fills thirteen report sections using idea inputs and a reviewed founder profile. Set `DEEPSEEK_API_KEY` and `DEEPSEEK_MODEL` to a model supported by your DeepSeek account. There is intentionally no assumed model ID. JSON output is parsed and validated server-side. Missing, duplicated, truncated or invalid sections fail as a whole and refund the known failed free request. `GET /health` exposes `analysisReady` separately from chat readiness; this is configuration status, not a live-provider smoke test.

When DeepSeek is configured it also serves `/v1/ai/respond`; OpenAI is only the legacy fallback. No OpenAI key is required for the DeepSeek setup. Both routes share the existing three-request free quota, Apple verification and rate limits. A model response is an assessment, not objective validation. Test representative ideas and source relevance before release.

Set `TAVILY_API_KEY` to enable external market research. Without it, or on search failure, competitor/momentum sections explain the research gap and omit unsupported metrics. Personal founder resources are not included in the search query. Only returned search URLs may be attached as sources. This prevents invented links, but does not prove every generated statement is supported; a human quality review is still necessary.

The app reviews the founder inputs and requests separate analysis consent before each analysis. The five most recent successful reports, inputs, sources and timestamps are saved locally. A response for an idea edited during the request is rejected. Regenerating a report preserves user-edited plan/validation workspaces. Initial blank business plans can use the generated sections. Existing data with no report still loads. Home score badges show a dash until an assessment exists.

The explicit `source/Configuration/Info.plist` now carries `KINDLING_API_BASE_URL` into the built app. Previously the custom generated-plist setting was not emitted. Debug accepts loopback HTTP; Release requires HTTPS and has no default server URL. Set the Release build setting to the deployed URL, rebuild and verify the actual app's Info.plist before uploading.

`render.yaml` is a deployment draft with persistent quota storage. Applying it provisions PAID hosting/storage: review the plan with the owner first. No hosting has been provisioned, credentials added, real provider calls made, or app uploaded by this change. Keep one instance for the file quota store. Check volume write permissions and persistence across restart before allowing production traffic.

Local simulator fixture: `node tests/analysis-smoke-server.mjs` from the candidate root, then run Debug. It binds only 127.0.0.1:8787 and emits clearly labeled LOCAL TEST reports with no real AI/search calls. Never deploy that script or use its reports as product evidence.

Provider references: https://api-docs.deepseek.com/guides/json_mode/ ; https://api-docs.deepseek.com/api/create-chat-completion/ ; https://docs.tavily.com/documentation/api-reference/endpoint/search ; https://render.com/docs/blueprint-spec ; https://render.com/docs/disks . DeepSeek pages were not retrievable during implementation; actual account/model compatibility remains a required live check.


## Opt-in daily market monitoring (October 13 follow-up)

This service is implemented locally and **disabled by default**. It does not deploy itself, publish the app, or send push notifications. The app reads an in-app update feed. Keep `MONITORING_ENABLED=false` until a real Apple sandbox entitlement, provider credentials, persistent-volume restart test, and source-quality smoke test succeed.

Configuration:

```dotenv
MONITORING_ENABLED=false
MONITORING_FILE=/data/market-monitors.json
MONITORING_DAILY_LIMIT=100
```

Production requires an explicitly configured persistent `MONITORING_FILE`. The same persistent volume may hold the separate quota file. Use **one server process/instance**, a writable volume, and filesystem access restricted to the service account; the file store is not a distributed database. Monitoring readiness additionally requires the DeepSeek model/key, Tavily key, Apple verifier, and `PRO_PURCHASES_ENABLED=true`. `/health` exposes `monitoringReady`; this is configuration readiness, not live credential verification. Disabled monitoring keeps authenticated status/deletion and local retention cleanup available without calling Apple or providers.

### API and authorization

- `POST /v1/monitoring/enroll`: `{signedTransaction, consent:true, idea:{id,title,summary,customer,problem,businessModel,category}, founder:{budget,hours,skills,experience,distribution,region}}`. Enrollment verifies the signed transaction and Apple's current subscription status. No client ID, boolean, client score, or client report grants monitoring access. One monitored idea is permitted per verified Apple environment/original transaction.
- The enrollment response is a flat snapshot plus `{id,token}`. The token is 32 random bytes encoded as 43 base64url characters. Save it in the app's Keychain; only its SHA256 hash is retained server-side. Treat it as a capability to read/delete this monitor. Never log it or put it in a URL.
- `POST /v1/monitoring/status`: `{id,token}` returns `status` (`active`, `paused`, `expired`), saved idea/founder input, nullable `lastCheckedAt`/`nextCheckAt`, `expiresAt`, `message`, up to ten events, and the latest server-created report if one exists. Reading status never triggers a paid check. Each event includes its date, confidence, citations, and optional server-generated current/previous planning-readiness estimate.
- `POST /v1/monitoring/delete`: `{id,token}` immediately removes the idea/profile, stored proof, baseline, report, and events. A missing/purged ID returns `{deleted:true}` so a lost response can be retried. Existing records always require their valid token.

Re-enrolling the same idea using valid Apple proof recovers/rotates the token without resetting the due time. Changing saved idea/founder inputs resets baseline/report/events but preserves the daily schedule and owner budget. A different idea returns 409 until the previous monitor is stopped. JSON fixtures produced by mocked tests are in `test/monitoring-enrollment-fixture.json` and `test/monitoring-response-fixture.json`; their fake capabilities have no live service behind them.

### Schedule, evidence and spend

A server timer checks for due work once a minute. Each owner can attempt one check per 24 hours, with a default **100 attempted checks per UTC day globally**. An attempt is durably reserved before Apple/provider calls; a crash or known failure conservatively consumes that day's attempt. The global budget and per-owner attempt marker survive restarts, token recovery, and delete/re-enroll. Queued records are processed in due-time order. Missed days do not create a backlog of paid catch-up jobs. Hosting suspension/downtime delays checks; this is a daily best-effort service, not an exact delivery-time promise.

Every due job re-verifies current Apple access, including revocation and grace-period expiry. It makes no research call when verification fails. Expired/revoked enrollment stops and clears its proof; valid re-enrollment is required to resume. Each allowed job makes **three Tavily queries** for market demand, competitors/alternatives, and trends. Search receives only idea title, customer, category and founder region. Empty, partial or failed research leaves the previous baseline and assessment unchanged and reports the check failure.

The first successful run stores an evidence baseline and emits no change event. Result reordering, whitespace, tracking parameters, metadata timestamps and disappearing results alone do not trigger reassessment. New/changed excerpt content is compared using one DeepSeek request; only a meaningful comparison citing the actual changed sources can proceed to a second DeepSeek request for a validated thirteen-section assessment. Thus a check costs up to three searches plus **two** model calls, rather than one model call for every poll. Nonmaterial evidence updates the baseline without a report/event. Invalid citations, incomplete JSON or failed analysis preserve the previous assessment and baseline.

Scores remain planning estimates, never observed business performance. No client report is trusted as a score baseline. The first changed-evidence report has no previous score. Subsequent readiness/entry adjustments require a specific explanation and at least one changed-source citation; otherwise the entire previous section is retained. Founder-fit is retained because founder inputs did not change. Preserved sections keep their dated sources. The update summary explains any readiness-estimate adjustment. These checks prevent fabricated links and unsupported numerical drift; they cannot guarantee that model interpretation of sources is correct. Test source relevance and reasoning quality before enabling public traffic.

### Stored data and retention

Opting into monitoring changes the data flow: the server persists the selected idea, founder profile, Apple signed proof for daily re-verification, evidence excerpts, current assessment, and ten recent events in an atomic mode-0600 file under a restricted directory. The capability is hashed, and the Apple owner identity is SHA256-hashed. Apple proof is not sent to Tavily or DeepSeek. DeepSeek receives the idea/profile, source evidence, and prior assessment for comparison and reassessment. No bodies, raw proofs, capabilities, identifiers or provider errors are logged by this code. Filesystem permissions are protection, **not encryption at rest**; use a host with appropriate storage encryption/access controls and protect backups separately.

Authenticated deletion removes private monitor data immediately; only a hashed owner/last-attempt marker remains until its 24-hour cost window passes. Paused or expired monitoring data is purged no later than 30 days after the pause/verified expiry boundary, on the next service maintenance pass. Maintenance runs every minute while the service is running, including when provider jobs are disabled; it cannot run while hosting is stopped. Invalid/corrupt storage fails closed instead of resetting budgets. The store is bounded to 1,000 monitors and 64 MiB. Configure host request/access logs to avoid request bodies, and document any separate host backups/log retention in the public privacy policy.

No APNs, email, SMS, or automatic App Store publication is included. Returning to the app or using Refresh reads existing updates only. The UI must clearly disclose background sharing, show the monitored input snapshot, require explicit consent when details change, and only apply a returned report to unchanged matching local idea/founder inputs.

### Monitoring verification

`node --test` covers capability authorization, verified enrollment, disabled-service behavior, baseline/no-change semantics, source validation, score preservation, provider failures, persistent budgets across restart/delete/re-enroll, due-order fairness, input revision guards, overlapping ticks, deletion during a running search, Apple expiry/outage, thirty-day purge, bounded history, and HTTP enrollment/status/delete. All external responses are mocked and tests use temporary local storage. `WRITE_MONITORING_FIXTURE=true node --test --test-name-pattern='meaningful evidence produces' test/monitoring.test.mjs` refreshes the fake response fixtures.
