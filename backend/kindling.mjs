import { createHash } from "node:crypto";

export const RESPONSE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    text: { type: "string" },
    insight: { type: "string" },
    action: { type: "string" },
    signal: {
      type: "string",
      enum: ["risk", "action", "opportunity", "research", "personal", "change"]
    }
  },
  required: ["text", "insight", "action", "signal"]
};

export function validateRequest(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) return "The request body must be JSON.";
  if (!body.idea || typeof body.idea !== "object") return "idea is required.";
  if (!Array.isArray(body.messages) || body.messages.length === 0) return "messages is required.";
  if (body.messages.length > 12) return "A maximum of 12 messages is allowed.";

  for (const message of body.messages) {
    if (!["user", "assistant"].includes(message?.role)) return "Every message needs a valid role.";
    if (typeof message?.content !== "string" || !message.content.trim()) return "Every message needs content.";
    if (message.content.length > 4_000) return "A message exceeds the 4,000 character limit.";
  }

  if (typeof body.clientId !== "string" || body.clientId.length < 8 || body.clientId.length > 128) {
    return "clientId is required.";
  }

  if (body.signedTransaction !== undefined && (typeof body.signedTransaction !== "string" ||
      body.signedTransaction.length < 1 || body.signedTransaction.length > 20_000)) {
    return "signedTransaction must be an App Store signed transaction.";
  }
  if (Object.hasOwn(body, "isPro")) return "Send a signed transaction, not a subscription flag.";

  return null;
}

export function buildOpenAIRequest(body, model = "gpt-5.6-luna") {
  const idea = body.idea;
  const context = {
    title: idea.title,
    summary: idea.summary,
    customer: idea.customer,
    problem: idea.problem,
    businessModel: idea.businessModel,
    category: idea.category,
    viabilityScore: idea.viabilityScore,
    founderFit: idea.founderFit,
    entryDifficulty: idea.entryDifficulty,
    competitorCount: idea.competitorCount,
    marketDirection: idea.marketDirection,
    lifecycle: idea.lifecycle,
    validationProgress: idea.validationProgress,
    businessPlanProgress: idea.businessPlanProgress,
    decision: idea.decision
  };

  const transcript = body.messages
    .slice(-12)
    .map((message) => `${message.role.toUpperCase()}: ${message.content}`)
    .join("\n\n");

  return {
    model,
    store: false,
    safety_identifier: createHash("sha256").update(body.clientId).digest("hex").slice(0, 64),
    instructions: [
      "You are Kindling AI, a candid, practical thought partner for early-stage founders.",
      "Use the supplied idea context and conversation, then search the web for current evidence before answering.",
      "Treat scores and founder inputs as planning hypotheses, not verified evidence.",
      "Support current market, competitor, pricing, regulatory, and trend claims with the web sources used for this response.",
      "Prefer primary sources, official statistics, company websites, and recent reputable reporting. Do not invent facts, URLs, customer evidence, or precise market sizes.",
      "Clearly distinguish sourced facts from inference and label uncertainty. Never promise outcomes. Keep the main answer concise and useful.",
      "Return one next action that is small, measurable, and appropriate to the idea's current lifecycle.",
      "This is general business guidance, not legal, tax, investment, medical, or financial advice."
    ].join(" "),
    input: `IDEA CONTEXT\n${JSON.stringify(context, null, 2)}\n\nCONVERSATION\n${transcript}`,
    reasoning: { effort: "low" },
    tools: [{ type: "web_search" }],
    tool_choice: "required",
    max_tool_calls: 3,
    include: ["web_search_call.action.sources"],
    text: {
      verbosity: "low",
      format: {
        type: "json_schema",
        name: "kindling_response",
        strict: true,
        schema: RESPONSE_SCHEMA
      }
    }
  };
}

export function extractSources(response) {
  const sources = [];
  const seen = new Set();

  for (const item of response?.output ?? []) {
    if (item?.type !== "web_search_call") continue;

    const candidates = item?.action?.sources ?? item?.sources ?? [];
    for (const source of candidates) {
      if (typeof source?.url !== "string") continue;

      let url;
      try {
        url = new URL(source.url);
      } catch {
        continue;
      }

      if (!["http:", "https:"].includes(url.protocol)) continue;
      if (seen.has(url.href)) continue;

      seen.add(url.href);
      sources.push({
        title: typeof source.title === "string" && source.title.trim()
          ? source.title.trim()
          : url.hostname.replace(/^www\./, ""),
        url: url.href
      });

      if (sources.length === 5) return sources;
    }
  }

  return sources;
}

export function extractOutputText(response) {
  if (typeof response?.output_text === "string" && response.output_text) return response.output_text;

  for (const item of response?.output ?? []) {
    for (const content of item?.content ?? []) {
      if (content?.type === "output_text" && typeof content.text === "string") return content.text;
    }
  }

  throw new Error("OpenAI returned no text output.");
}
