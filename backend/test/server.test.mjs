import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createServer } from "../server.mjs";
import { FreeUsageStore, RateLimiter } from "../usage.mjs";

const request = { clientId: "installation-123", idea: { title: "idea" }, messages: [{ role: "user", content: "Help" }] };
const validOutput = { text: "Answer", insight: "Insight", action: "Action", signal: "action" };
async function start(t, overrides = {}) {
  const directory = mkdtempSync(join(tmpdir(), "kindling-test-"));
  const quotaPath = join(directory, "usage.json");
  const usage = new FreeUsageStore(quotaPath);
  const server = createServer({
    env: { OPENAI_API_KEY: "fake-offline-test-key", PRO_PURCHASES_ENABLED: "true" }, usage,
    apple: { ready: true, verify: async () => ({ environment: "Sandbox", originalTransactionId: "original" }) },
    fetchImpl: async () => ({ ok: true, json: async () => ({ output_text: JSON.stringify(validOutput) }) }),
    logger: { error() {} }, ...overrides
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(async () => { await new Promise((resolve) => server.close(resolve)); rmSync(directory, { recursive: true, force: true }); });
  const base = `http://127.0.0.1:${server.address().port}`;
  return { quotaPath, usage, getHealth: () => fetch(`${base}/health`).then((r) => r.json()),
    post: (body = request) => fetch(`${base}/v1/ai/respond`, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) }) };
}

test("three free requests work, fourth is blocked by server and remains blocked after restart", async (t) => {
  const { post, quotaPath } = await start(t);
  for (let i = 0; i < 3; i++) assert.equal((await post()).status, 200);
  assert.equal((await post()).status, 402);
  assert.throws(() => new FreeUsageStore(quotaPath).reserve(request.clientId), { status: 402 });
  assert.ok(!readFileSync(quotaPath, "utf8").includes(request.clientId));
});
test("failed upstream request refunds free allowance and preserves safe response", async (t) => {
  const { post, usage } = await start(t, { fetchImpl: async () => { throw new Error("secret upstream error"); } });
  for (let i = 0; i < 4; i++) {
    const response = await post();
    assert.equal(response.status, 502);
    assert.ok(!(await response.text()).includes("secret"));
  }
  assert.doesNotThrow(() => usage.reserve(request.clientId));
});
test("verified paid calls do not consume free usage", async (t) => {
  const { post } = await start(t);
  for (let i = 0; i < 4; i++) assert.equal((await post({ ...request, signedTransaction: "proof" })).status, 200);
  for (let i = 0; i < 3; i++) assert.equal((await post()).status, 200);
});
test("invalid proof never silently falls back to the free tier", async (t) => {
  let calls = 0;
  const { post } = await start(t, {
    apple: { ready: true, verify: async () => { throw Object.assign(new Error("Invalid subscription."), { status: 401 }); } },
    fetchImpl: async () => { calls++; throw new Error("should not call"); }
  });
  assert.equal((await post({ ...request, signedTransaction: "forged" })).status, 401);
  assert.equal(calls, 0);
});
test("client boolean is not evidence of a subscription", async (t) => {
  const { post } = await start(t);
  assert.equal((await post({ ...request, isPro: true })).status, 400);
});
test("unconfigured production service reports unavailable and does not invite purchases", async (t) => {
  const { post, getHealth } = await start(t, { env: { NODE_ENV: "production" }, usage: undefined });
  assert.equal((await getHealth()).subscriptionsReady, false);
  assert.equal((await post()).status, 503);
});
test("purchase readiness requires explicit launch switch even when keys are configured", async (t) => {
  const { getHealth } = await start(t, { env: { OPENAI_API_KEY: "fake" } });
  assert.equal((await getHealth()).subscriptionsReady, false);
});
test("rate limiter expires entries and bounds requests independently of install ID", () => {
  let now = 0;
  const limiter = new RateLimiter({ limit: 2, windowMs: 100, now: () => now });
  assert.equal(limiter.exceeds("ip"), false);
  assert.equal(limiter.exceeds("ip"), false);
  assert.equal(limiter.exceeds("ip"), true);
  now = 100;
  assert.equal(limiter.exceeds("ip"), false);
});

test("simultaneous free requests cannot exceed the allowance", async (t) => {
  const { post } = await start(t);
  const responses = await Promise.all(Array.from({ length: 4 }, () => post()));
  assert.deepEqual(responses.map((r) => r.status).sort(), [200, 200, 200, 402]);
});
