import type { ConfigService } from "@nestjs/config";
import { describe, expect, it, vi } from "vitest";

import { featureEnabled } from "../src/config/feature-flags.js";

function config(value?: string): ConfigService {
  return {
    get: vi.fn(() => value),
  } as unknown as ConfigService;
}

describe("provider feature flags", () => {
  it("keeps existing configured behavior unless explicitly disabled", () => {
    expect(featureEnabled(config(undefined), "FEATURE")).toBe(true);
    expect(featureEnabled(config("true"), "FEATURE")).toBe(true);
  });

  it.each(["false", "0", "off", "disabled"])(
    "treats %s as a kill-switch value",
    (value) => {
      expect(featureEnabled(config(value), "FEATURE")).toBe(false);
    },
  );
});
