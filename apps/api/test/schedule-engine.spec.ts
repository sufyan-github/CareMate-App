import { describe, expect, it } from "vitest";

import { ScheduleEngine } from "../src/medication-schedule/schedule-engine.js";

describe("ScheduleEngine", () => {
  const engine = new ScheduleEngine();

  it("generates weekly occurrences and honors explicit exclusions", () => {
    const result = engine.generate({
      daysOfWeek: [1, 3],
      endDate: "2026-08-23",
      excludedDates: ["2026-08-19"],
      horizonDays: 30,
      quantityUnit: "TABLET",
      quantityValue: 1,
      recurrence: "WEEKLY",
      startDate: "2026-08-17",
      times: ["08:00"],
      timezone: "Asia/Dhaka",
    });

    expect(result.occurrences).toEqual([
      expect.objectContaining({
        plannedAt: new Date("2026-08-17T02:00:00.000Z"),
        plannedLocalDateTime: "2026-08-17T08:00",
        quantityUnit: "TABLET",
        quantityValue: 1,
      }),
    ]);
    expect(result.generatedThroughDate).toBe("2026-08-23");
    expect(result.warnings).toContain("EXCLUDED_DATES_SKIPPED");
  });

  it("handles leap-day boundaries deterministically", () => {
    const result = engine.generate({
      endDate: "2028-03-01",
      excludedDates: ["2028-02-29"],
      horizonDays: 30,
      quantityUnit: "CAPSULE",
      quantityValue: 2,
      recurrence: "DAILY",
      startDate: "2028-02-28",
      times: ["20:00"],
      timezone: "Asia/Dhaka",
    });

    expect(result.occurrences.map((item) => item.plannedLocalDateTime)).toEqual(
      ["2028-02-28T20:00", "2028-03-01T20:00"],
    );
  });

  it("bounds open schedules and reports the rolling horizon", () => {
    const result = engine.generate({
      excludedDates: [],
      horizonDays: 30,
      quantityUnit: "ML",
      quantityValue: 5,
      recurrence: "DAILY",
      startDate: "2026-08-17",
      times: ["08:00"],
      timezone: "Asia/Dhaka",
    });

    expect(result.occurrences).toHaveLength(30);
    expect(result.generatedThroughDate).toBe("2026-09-15");
    expect(result.warnings).toContain("OPEN_ENDED_ROLLING_HORIZON");
  });

  it("rejects nonexistent DST wall times and warns on ambiguous times", () => {
    let nonexistentError: unknown;
    try {
      engine.generate({
        endDate: "2026-03-08",
        excludedDates: [],
        horizonDays: 1,
        quantityUnit: "TABLET",
        quantityValue: 1,
        recurrence: "DAILY",
        startDate: "2026-03-08",
        times: ["02:30"],
        timezone: "America/New_York",
      });
    } catch (error) {
      nonexistentError = error;
    }
    expect(nonexistentError).toMatchObject({
      response: {
        error: {
          code: "SCHEDULE_INVALID",
          message:
            "The local time 2026-03-08 02:30 does not exist in America/New_York.",
        },
      },
    });

    const ambiguous = engine.generate({
      endDate: "2026-11-01",
      excludedDates: [],
      horizonDays: 1,
      quantityUnit: "TABLET",
      quantityValue: 1,
      recurrence: "DAILY",
      startDate: "2026-11-01",
      times: ["01:30"],
      timezone: "America/New_York",
    });
    expect(ambiguous.warnings).toContain("AMBIGUOUS_LOCAL_TIME_EARLIER_USED");
    expect(ambiguous.occurrences[0]?.plannedAt.toISOString()).toBe(
      "2026-11-01T05:30:00.000Z",
    );
  });

  it("never emits duplicate deterministic keys across a recurrence matrix", () => {
    for (let horizonDays = 1; horizonDays <= 60; horizonDays += 7) {
      for (const recurrence of ["DAILY", "WEEKLY"] as const) {
        const input = {
          daysOfWeek: recurrence === "WEEKLY" ? [1, 3, 5] : [],
          excludedDates: ["2026-08-20"],
          horizonDays,
          quantityUnit: "TABLET",
          quantityValue: 1,
          recurrence,
          startDate: "2026-08-17",
          times: ["08:00", "20:00"],
          timezone: "Asia/Dhaka",
        };
        const first = engine.generate(input).occurrences;
        const second = engine.generate(input).occurrences;
        const keys = first.map((item) => item.plannedLocalDateTime);
        expect(new Set(keys).size).toBe(keys.length);
        expect(second).toEqual(first);
      }
    }
  });
});
