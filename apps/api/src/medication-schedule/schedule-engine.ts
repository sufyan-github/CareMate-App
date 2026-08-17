import { HttpStatus, Injectable } from "@nestjs/common";

import { AuthError } from "../auth/auth-error.js";

export type ScheduleRecurrence = "DAILY" | "WEEKLY";

export type ScheduleOccurrence = {
  plannedAt: Date;
  plannedLocalDateTime: string;
  quantityUnit: string;
  quantityValue: number;
};

export type ScheduleGenerationResult = {
  generatedThroughDate: string;
  occurrences: ScheduleOccurrence[];
  warnings: string[];
};

export type ScheduleGenerationInput = {
  daysOfWeek?: number[];
  endDate?: string;
  excludedDates?: string[];
  horizonDays?: number;
  quantityUnit?: string;
  quantityValue?: number;
  recurrence?: ScheduleRecurrence;
  startDate: string;
  times: string[];
  timezone: string;
};

@Injectable()
export class ScheduleEngine {
  generate(input: ScheduleGenerationInput): ScheduleGenerationResult {
    this.validateTimezone(input.timezone);
    const start = this.parseDate(input.startDate);
    const configuredEnd = input.endDate
      ? this.parseDate(input.endDate)
      : undefined;
    if (configuredEnd && configuredEnd.getTime() < start.getTime()) {
      this.invalid("The end date must be on or after the start date.");
    }
    const horizonDays = input.horizonDays ?? 30;
    if (
      !Number.isInteger(horizonDays) ||
      horizonDays < 1 ||
      horizonDays > 366
    ) {
      this.invalid("The generation horizon must be between 1 and 366 days.");
    }
    const horizonEnd = this.parseDate(
      this.addDays(input.startDate, horizonDays - 1),
    );
    const effectiveEnd =
      configuredEnd && configuredEnd < horizonEnd ? configuredEnd : horizonEnd;
    const generatedThroughDate = effectiveEnd.toISOString().slice(0, 10);
    const recurrence = input.recurrence ?? "DAILY";
    const daysOfWeek = [...new Set(input.daysOfWeek ?? [])].sort();
    if (
      daysOfWeek.some((day) => !Number.isInteger(day) || day < 1 || day > 7)
    ) {
      this.invalid("Weekly schedule days must be ISO weekdays from 1 to 7.");
    }
    if (recurrence === "WEEKLY" && daysOfWeek.length === 0) {
      this.invalid("Choose at least one weekday for a weekly schedule.");
    }
    const times = [...new Set(input.times)].sort();
    if (times.length !== input.times.length) {
      this.invalid("Choose each dose time only once.");
    }
    if (
      times.length === 0 ||
      times.some((time) => !/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(time))
    ) {
      this.invalid("Choose at least one valid 24-hour dose time.");
    }
    const quantityValue = input.quantityValue ?? 1;
    const quantityUnit = input.quantityUnit ?? "DOSE";
    if (!Number.isFinite(quantityValue) || quantityValue <= 0) {
      this.invalid("Dose quantity must be greater than zero.");
    }
    const excludedDates = new Set(input.excludedDates ?? []);
    for (const date of excludedDates) this.parseDate(date);

    const warnings = new Set<string>();
    if (!configuredEnd) warnings.add("OPEN_ENDED_ROLLING_HORIZON");
    if (configuredEnd && configuredEnd > horizonEnd) {
      warnings.add("ROLLING_HORIZON_TRUNCATED");
    }
    const days =
      Math.floor((effectiveEnd.getTime() - start.getTime()) / 86_400_000) + 1;
    const occurrences: ScheduleOccurrence[] = [];
    for (let offset = 0; offset < days; offset += 1) {
      const date = this.addDays(input.startDate, offset);
      if (excludedDates.has(date)) {
        warnings.add("EXCLUDED_DATES_SKIPPED");
        continue;
      }
      const dateValue = this.parseDate(date);
      const isoWeekday = dateValue.getUTCDay() || 7;
      if (recurrence === "WEEKLY" && !daysOfWeek.includes(isoWeekday)) {
        continue;
      }
      for (const time of times) {
        const resolved = this.localToUtc(date, time, input.timezone);
        if (resolved.ambiguous) {
          warnings.add("AMBIGUOUS_LOCAL_TIME_EARLIER_USED");
        }
        occurrences.push({
          plannedAt: resolved.value,
          plannedLocalDateTime: `${date}T${time}`,
          quantityUnit,
          quantityValue,
        });
      }
    }
    return {
      generatedThroughDate,
      occurrences,
      warnings: [...warnings],
    };
  }

  private localToUtc(
    date: string,
    time: string,
    timezone: string,
  ): { ambiguous: boolean; value: Date } {
    const [year = 0, month = 0, day = 0] = date.split("-").map(Number);
    const [hour = 0, minute = 0] = time.split(":").map(Number);
    const target = Date.UTC(year, month - 1, day, hour, minute);
    let estimate = target;
    const formatter = this.formatter(timezone);
    for (let iteration = 0; iteration < 4; iteration += 1) {
      const parts = this.parts(formatter, new Date(estimate));
      const rendered = Date.UTC(
        parts.year,
        parts.month - 1,
        parts.day,
        parts.hour,
        parts.minute,
      );
      estimate += target - rendered;
    }
    const candidates = new Set<number>();
    for (let minutes = -180; minutes <= 180; minutes += 30) {
      const candidate = new Date(estimate + minutes * 60_000);
      if (this.matches(formatter, candidate, year, month, day, hour, minute)) {
        candidates.add(candidate.getTime());
      }
    }
    const ordered = [...candidates].sort((left, right) => left - right);
    if (ordered.length === 0) {
      this.invalid(
        `The local time ${date} ${time} does not exist in ${timezone}.`,
      );
    }
    return { ambiguous: ordered.length > 1, value: new Date(ordered[0]!) };
  }

  private formatter(timezone: string): Intl.DateTimeFormat {
    return new Intl.DateTimeFormat("en-CA", {
      day: "2-digit",
      hour: "2-digit",
      hourCycle: "h23",
      minute: "2-digit",
      month: "2-digit",
      timeZone: timezone,
      year: "numeric",
    });
  }

  private parts(formatter: Intl.DateTimeFormat, value: Date) {
    const parts = Object.fromEntries(
      formatter
        .formatToParts(value)
        .filter((part) => part.type !== "literal")
        .map((part) => [part.type, Number(part.value)]),
    ) as Record<string, number>;
    return {
      day: parts.day!,
      hour: parts.hour!,
      minute: parts.minute!,
      month: parts.month!,
      year: parts.year!,
    };
  }

  private matches(
    formatter: Intl.DateTimeFormat,
    value: Date,
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
  ): boolean {
    const rendered = this.parts(formatter, value);
    return (
      rendered.year === year &&
      rendered.month === month &&
      rendered.day === day &&
      rendered.hour === hour &&
      rendered.minute === minute
    );
  }

  private parseDate(value: string): Date {
    const parsed = new Date(`${value}T00:00:00.000Z`);
    if (
      Number.isNaN(parsed.getTime()) ||
      parsed.toISOString().slice(0, 10) !== value
    ) {
      this.invalid("Choose a valid calendar date.");
    }
    return parsed;
  }

  private addDays(value: string, days: number): string {
    const date = this.parseDate(value);
    date.setUTCDate(date.getUTCDate() + days);
    return date.toISOString().slice(0, 10);
  }

  private validateTimezone(timezone: string): void {
    try {
      Intl.DateTimeFormat("en", { timeZone: timezone }).format();
    } catch {
      this.invalid("Choose a valid timezone.");
    }
  }

  private invalid(message: string): never {
    throw new AuthError(HttpStatus.BAD_REQUEST, "SCHEDULE_INVALID", message);
  }
}
