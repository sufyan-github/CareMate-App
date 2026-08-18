import { describe, expect, it } from "vitest";

import { buildOperationalEvent } from "../src/observability/operational-metrics.interceptor.js";
import { resolveRequestId } from "../src/observability/request-context.js";

describe("privacy-safe operational diagnostics", () => {
  it("accepts safe correlation IDs and replaces unsafe values", () => {
    expect(resolveRequestId("competition_check_01")).toBe(
      "competition_check_01",
    );
    expect(resolveRequestId("Bearer secret token")).toMatch(/^req_[A-Z0-9]+$/u);
  });

  it("emits only route-handler metadata, outcome, and duration", () => {
    const event = buildOperationalEvent({
      controller: "HealthController",
      durationMs: 12.6,
      handler: "getHealth",
      method: "GET",
      requestId: "competition_check_01",
      statusCode: 200,
    });

    expect(event).toEqual({
      controller: "HealthController",
      durationMs: 13,
      event: "http_request_completed",
      handler: "getHealth",
      method: "GET",
      outcome: "success",
      requestId: "competition_check_01",
      statusCode: 200,
    });
    expect(event).not.toHaveProperty("body");
    expect(event).not.toHaveProperty("headers");
    expect(event).not.toHaveProperty("url");
    expect(event).not.toHaveProperty("userId");
  });
});
