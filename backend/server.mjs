import http from "node:http";
import { createMonitoringService } from "./monitoring.mjs";
import { validateAnalysis, generateAnalysis, generateDeepSeekChat } from "./analysis.mjs";
import { pathToFileURL } from "node:url";
import { buildOpenAIRequest, extractOutputText, extractSources, validateRequest } from "./kindling.mjs";
import { configureAppleSubscriptions } from "./apple-subscriptions.mjs";
import { FreeUsageStore, identityHash, RateLimiter } from "./usage.mjs";

function json(response, status, value, extraHeaders = {}) {
  response.writeHead(status, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store", ...extraHeaders });
  response.end(JSON.stringify(value));
}

async function readJSON(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > 128 * 1024) throw Object.assign(new Error("Request too large."), { status: 413 });
    chunks.push(chunk);
  }
  try { return JSON.parse(Buffer.concat(chunks).toString("utf8")); }
  catch { throw Object.assign(new Error("Invalid JSON."), { status: 400 }); }
}

export function createServer({ env = process.env, apple = configureAppleSubscriptions(env), usage,
  fetchImpl = fetch, logger = console, monitoring, now = Date.now } = {}) {
  const monitors = monitoring ?? createMonitoringService({ env, apple, fetchImpl, logger, now });
  const model = env.OPENAI_MODEL ?? "gpt-5.6-luna";
  const origin = env.ALLOWED_ORIGIN ?? "";
  // Production must explicitly point to a persistent volume. No reset-on-restart fallback.
  const quotaPath = env.QUOTA_FILE ?? (env.NODE_ENV === "production" ? undefined : "./data/free-usage.json");
  const quotas = usage ?? (quotaPath ? new FreeUsageStore(quotaPath) : undefined);
  const ipLimiter = new RateLimiter({ limit: Number(env.RATE_LIMIT_REQUESTS ?? 20) });
  const paidLimiter = new RateLimiter({ limit: Number(env.RATE_LIMIT_REQUESTS ?? 20) });
  const globalLimiter = new RateLimiter({ limit: Number(env.GLOBAL_RATE_LIMIT_REQUESTS ?? 120) });
  for (const value of [ipLimiter.limit, paidLimiter.limit, globalLimiter.limit]) {
    if (!Number.isInteger(value) || value < 1) throw new Error("Rate limits must be positive integers.");
  }
  const deepSeekReady = Boolean(env.DEEPSEEK_API_KEY && env.DEEPSEEK_MODEL);
  const aiReady = Boolean((deepSeekReady || env.OPENAI_API_KEY) && quotas);
  // Explicit switch stays off until the operator completes a real sandbox smoke test.
  const analysisReady = Boolean(deepSeekReady && quotas);
  const subscriptionsReady = aiReady && apple.ready && env.PRO_PURCHASES_ENABLED === "true";
  const cors = (request) => origin && request.headers.origin === origin
    ? { "access-control-allow-origin": origin, vary: "Origin" } : {};

  async function handleAI(request, response, analysis = false) {
    if (!(analysis ? analysisReady : aiReady)) return json(response, 503, { error: "Kindling AI is temporarily unavailable." }, cors(request));
    // Ignore client-controlled forwarding headers. Configure the host's edge
    // limiter for actual client IPs; the application also limits all requests.
    const ip = identityHash(request.socket.remoteAddress ?? "unknown");
    if (ipLimiter.exceeds(ip) || globalLimiter.exceeds("global")) {
      return json(response, 429, { error: "Too many requests. Please try again shortly." }, cors(request));
    }
    const body = await readJSON(request);
    const validationError = analysis ? validateAnalysis(body) : validateRequest(body);
    if (validationError) return json(response, 400, { error: validationError }, cors(request));
    let refundQuota;
    if (body.signedTransaction) {
      const entitlement = await apple.verify(body.signedTransaction);
      if (paidLimiter.exceeds(identityHash(`${entitlement.environment}:${entitlement.originalTransactionId}`))) {
        return json(response, 429, { error: "Too many requests. Please try again shortly." }, cors(request));
      }
    } else {
      refundQuota = quotas.reserve(body.clientId);
    }
    try {
      if (analysis) return json(response, 200, await generateAnalysis(body, env, fetchImpl), cors(request));
      if (deepSeekReady) return json(response, 200, await generateDeepSeekChat(body, env, fetchImpl), cors(request));
      const openAIResponse = await fetchImpl("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: { authorization: `Bearer ${env.OPENAI_API_KEY}`, "content-type": "application/json" },
        body: JSON.stringify(buildOpenAIRequest(body, model)),
        signal: AbortSignal.timeout(45_000)
      });
      const openAIData = await openAIResponse.json().catch(() => ({}));
      if (!openAIResponse.ok) throw new Error("upstream_failure");
      const parsed = JSON.parse(extractOutputText(openAIData));
      if (!["text", "insight", "action"].every((key) => typeof parsed[key] === "string") ||
          !["risk", "action", "opportunity", "research", "personal", "change"].includes(parsed.signal)) {
        throw new Error("upstream_format");
      }
      return json(response, 200, {
        text: parsed.text, insight: parsed.insight, action: parsed.action, signal: parsed.signal,
        sources: extractSources(openAIData), researchedAt: new Date().toISOString()
      }, cors(request));
    } catch {
      refundQuota?.();
      // Do not log prompts, receipts, identifiers, private keys, or upstream bodies.
      logger.error("AI request failed");
      return json(response, 502, { error: "Kindling AI is temporarily unavailable. Please try again." }, cors(request));
    }
  }

  const server = http.createServer({ requestTimeout: 130_000, headersTimeout: 15_000 }, async (request, response) => {
    try {
      if (request.method === "GET" && request.url === "/health") {
        return json(response, 200, { ok: true, aiReady, analysisReady, researchReady: Boolean(env.TAVILY_API_KEY), subscriptionsReady, monitoringReady: monitors.ready }, cors(request));
      }
      if (request.method === "OPTIONS" && ["/v1/ai/respond", "/v1/ideas/analyze", "/v1/monitoring/enroll", "/v1/monitoring/status", "/v1/monitoring/delete"].includes(request.url)) {
        response.writeHead(204, { ...cors(request), "access-control-allow-headers": "content-type", "access-control-allow-methods": "POST, OPTIONS" });
        return response.end();
      }
      if (request.method === "POST" && ["/v1/monitoring/enroll", "/v1/monitoring/status", "/v1/monitoring/delete"].includes(request.url)) {
        if (ipLimiter.exceeds(identityHash(request.socket.remoteAddress ?? "unknown"))) return json(response, 429, { error: "Too many requests. Please try again shortly." }, cors(request));
        const body = await readJSON(request);
        const action = request.url.split("/").at(-1);
        const result = action === "enroll" ? await monitors.enroll(body) : action === "status" ? monitors.status(body) : monitors.remove(body);
        return json(response, 200, result, cors(request));
      }
      if (request.method === "POST" && request.url === "/v1/ai/respond") return await handleAI(request, response);
      if (request.method === "POST" && request.url === "/v1/ideas/analyze") return await handleAI(request, response, true);
      return json(response, 404, { error: "Not found." }, cors(request));
    } catch (error) {
      const status = Number(error?.status ?? 500);
      if (status >= 500) logger.error("Request failed", status);
      return json(response, status, { error: status === 500 ? "Unexpected server error." : error.message }, cors(request));
    }
  });
  server.once("listening", () => monitors.start());
  server.once("close", () => monitors.stop());
  return server;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT ?? 8787);
  createServer().listen(port, process.env.HOST ?? "127.0.0.1", () => console.log(`Kindling backend listening on port ${port}`));
}
