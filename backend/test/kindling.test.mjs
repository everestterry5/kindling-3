import test from "node:test";
import assert from "node:assert/strict";
import { buildOpenAIRequest, extractOutputText, extractSources, validateRequest } from "../kindling.mjs";

const valid = {
  clientId: "install-12345678",
  idea: { title: "AI Meal Planning", lifecycle: "Validating" },
  messages: [{ role: "user", content: "What should I validate next?" }]
};

test("validates a Kindling request", () => {
  assert.equal(validateRequest(valid), null);
  assert.match(validateRequest({}), /idea/);
});

test("builds a private structured Responses API request", () => {
  const request = buildOpenAIRequest(valid);
  assert.equal(request.model, "gpt-5.6-luna");
  assert.equal(request.store, false);
  assert.equal(request.text.format.type, "json_schema");
  assert.deepEqual(request.tools, [{ type: "web_search" }]);
  assert.equal(request.tool_choice, "required");
  assert.deepEqual(request.include, ["web_search_call.action.sources"]);
  assert.equal(request.safety_identifier.length, 64);
  assert.match(request.input, /What should I validate next/);
});

test("extracts Responses API output", () => {
  assert.equal(extractOutputText({ output_text: "hello" }), "hello");
  assert.equal(extractOutputText({ output: [{ content: [{ type: "output_text", text: "fallback" }] }] }), "fallback");
});

test("extracts and deduplicates verified web-search sources", () => {
  const response = {
    output: [{
      type: "web_search_call",
      action: {
        sources: [
          { title: "Official data", url: "https://example.gov/data" },
          { title: "Duplicate", url: "https://example.gov/data" },
          { title: "Unsafe", url: "javascript:alert(1)" }
        ]
      }
    }]
  };

  assert.deepEqual(extractSources(response), [
    { title: "Official data", url: "https://example.gov/data" }
  ]);
});
