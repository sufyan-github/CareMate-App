import { HttpStatus, Injectable } from "@nestjs/common";
import { ulid } from "ulid";

import { AuthError } from "../auth/auth-error.js";
import { DatabaseService } from "../database/database.service.js";
import { DoseLifecycleService } from "../dose-lifecycle/dose-lifecycle.service.js";
import type {
  CreateMedicationScheduleDto,
  DoseOccurrenceWindowDto,
  ScheduleCommandDto,
  UpdateMedicationScheduleDto,
} from "./medication-schedule.dto.js";
import {
  ScheduleEngine,
  type ScheduleOccurrence,
  type ScheduleRecurrence,
} from "./schedule-engine.js";

@Injectable()
export class MedicationScheduleService {
  constructor(
    private readonly database: DatabaseService,
    private readonly doseLifecycle: DoseLifecycleService,
    private readonly engine: ScheduleEngine,
  ) {}

  async create(
    userId: string,
    medicationId: string,
    input: CreateMedicationScheduleDto,
  ) {
    const medication = await this.database.medication.findFirst({
      include: { instructions: true, patientProfile: true },
      where: { id: medicationId, patientProfile: { ownerUserId: userId } },
    });
    if (!medication?.instructions) this.notFound();
    if (medication.status !== "ACTIVE") {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "MEDICATION_NOT_ACTIVE",
        "Resume the medicine before creating a schedule.",
      );
    }
    if (input.timezone !== medication.patientProfile.timezone) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "SCHEDULE_TIMEZONE_MISMATCH",
        "Preview the schedule in the patient profile timezone.",
      );
    }
    const requestedEndDate = input.openEnded ? undefined : input.endDate;
    const generationInput = {
      ...(input.daysOfWeek ? { daysOfWeek: input.daysOfWeek } : {}),
      ...(requestedEndDate ? { endDate: requestedEndDate } : {}),
      excludedDates: input.excludedDates ?? [],
      quantityUnit: medication.instructions.quantityUnit,
      quantityValue: medication.instructions.quantityValue,
      recurrence: input.recurrence ?? ("DAILY" as const),
      startDate: input.startDate,
      times: input.times,
      timezone: input.timezone,
    };
    const previewGeneration = this.engine.generate({
      ...generationInput,
      horizonDays: this.previewHorizonDays(input.startDate, requestedEndDate),
    });
    const preview = {
      activation: input.activation,
      occurrences: previewGeneration.occurrences.map((occurrence) => ({
        plannedAt: occurrence.plannedAt.toISOString(),
        plannedLocalDateTime: occurrence.plannedLocalDateTime,
      })),
      quantityRequired: previewGeneration.occurrences.reduce(
        (total, occurrence) => total + occurrence.quantityValue,
        0,
      ),
      quantityUnit: medication.instructions.quantityUnit,
      warnings: previewGeneration.warnings,
    };
    if (input.activation === "PREVIEW") {
      return this.response(preview);
    }
    const existing = await this.database.medicationSchedule.findFirst({
      where: { medicationId, status: { in: ["ACTIVE", "PAUSED"] } },
    });
    if (existing) this.activeScheduleConflict();
    const activationGeneration = this.engine.generate({
      ...generationInput,
      horizonDays: 30,
    });
    const scheduleId = ulid();
    let schedule;
    try {
      schedule = await this.database.$transaction(async (transaction) => {
        const created = await transaction.medicationSchedule.create({
          data: {
            daysOfWeekJson: JSON.stringify(input.daysOfWeek ?? []),
            endDate: requestedEndDate ?? null,
            excludedDatesJson: JSON.stringify(input.excludedDates ?? []),
            generatedThroughDate: activationGeneration.generatedThroughDate,
            id: scheduleId,
            medicationId,
            recurrence: input.recurrence ?? "DAILY",
            startDate: input.startDate,
            timesJson: JSON.stringify([...input.times].sort()),
            timezone: input.timezone,
          },
        });
        await transaction.doseOccurrence.createMany({
          data: activationGeneration.occurrences.map((occurrence) => ({
            id: ulid(),
            medicationId,
            patientProfileId: medication.patientProfileId,
            plannedAt: occurrence.plannedAt,
            plannedLocalDateTime: occurrence.plannedLocalDateTime,
            quantityUnit: occurrence.quantityUnit,
            quantityValue: occurrence.quantityValue,
            ruleRevision: created.revision,
            scheduleId,
            timezone: input.timezone,
          })),
        });
        return created;
      });
    } catch (error) {
      if (this.isUniqueConstraint(error)) this.activeScheduleConflict();
      throw error;
    }
    return this.response({ ...preview, schedule: this.scheduleView(schedule) });
  }

  async listOccurrences(
    userId: string,
    profileId: string,
    window: DoseOccurrenceWindowDto,
  ) {
    const access = await this.readableProfile(userId, profileId);
    if (window.to < window.from) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "OCCURRENCE_WINDOW_INVALID",
        "The end date must be on or after the start date.",
      );
    }
    await this.extendRollingHorizon(profileId, window.to);
    await this.doseLifecycle.evaluateWindow(profileId, window.from, window.to);
    const occurrences = await this.database.doseOccurrence.findMany({
      include: { medication: true },
      orderBy: { plannedAt: "asc" },
      where: {
        patientProfileId: profileId,
        plannedLocalDateTime: {
          gte: `${window.from}T00:00`,
          lte: `${window.to}T23:59`,
        },
        status: { not: "CANCELLED" },
      },
    });
    return this.response(
      occurrences.map((occurrence) => ({
        id: occurrence.id,
        medication: {
          displayName: occurrence.medication.displayName,
          form: occurrence.medication.form,
          id: occurrence.medication.id,
        },
        plannedAt: occurrence.plannedAt.toISOString(),
        plannedLocalDateTime: occurrence.plannedLocalDateTime,
        quantityUnit: occurrence.quantityUnit,
        quantityValue: occurrence.quantityValue,
        ruleRevision: occurrence.ruleRevision,
        scheduleId: occurrence.scheduleId,
        ...(access.canViewDoseOutcomes
          ? {
              confirmedAt: occurrence.confirmedAt?.toISOString() ?? null,
              missedAt: occurrence.missedAt?.toISOString() ?? null,
              reminderSentAt: occurrence.reminderSentAt?.toISOString() ?? null,
              responseDueAt: occurrence.responseDueAt?.toISOString() ?? null,
              snoozeCount: occurrence.snoozeCount,
              snoozedUntil: occurrence.snoozedUntil?.toISOString() ?? null,
              status: occurrence.status,
              timingClassification: occurrence.timingClassification,
            }
          : {}),
        timezone: occurrence.timezone,
        version: occurrence.version,
      })),
    );
  }

  private async extendRollingHorizon(
    profileId: string,
    requestedThroughDate: string,
  ): Promise<void> {
    const schedules = await this.database.medicationSchedule.findMany({
      include: {
        medication: { include: { instructions: true, patientProfile: true } },
      },
      where: {
        medication: { patientProfileId: profileId },
        status: "ACTIVE",
      },
    });
    for (const schedule of schedules) {
      if (!schedule.medication.instructions) continue;
      const today = this.localDateInTimezone(schedule.timezone);
      const rollingLimit = this.addDays(
        today,
        schedule.generationHorizonDays - 1,
      );
      const configuredLimit = schedule.endDate ?? rollingLimit;
      const target = [
        requestedThroughDate,
        rollingLimit,
        configuredLimit,
      ].sort()[0]!;
      if (target <= schedule.generatedThroughDate) continue;
      const nextDate = this.addDays(schedule.generatedThroughDate, 1);
      const horizonDays = this.daysInclusive(nextDate, target);
      const generation = this.engine.generate({
        daysOfWeek: JSON.parse(schedule.daysOfWeekJson) as number[],
        endDate: target,
        excludedDates: JSON.parse(schedule.excludedDatesJson) as string[],
        horizonDays,
        quantityUnit: schedule.medication.instructions.quantityUnit,
        quantityValue: schedule.medication.instructions.quantityValue,
        recurrence: schedule.recurrence as ScheduleRecurrence,
        startDate: nextDate,
        times: JSON.parse(schedule.timesJson) as string[],
        timezone: schedule.timezone,
      });
      await this.database.$transaction(async (transaction) => {
        const reserved = await transaction.medicationSchedule.updateMany({
          data: { generatedThroughDate: generation.generatedThroughDate },
          where: {
            generatedThroughDate: schedule.generatedThroughDate,
            id: schedule.id,
            revision: schedule.revision,
            status: "ACTIVE",
          },
        });
        if (reserved.count === 0) return;
        await transaction.doseOccurrence.createMany({
          data: generation.occurrences.map((occurrence) =>
            this.occurrenceData(schedule, occurrence, schedule.revision),
          ),
        });
      });
    }
  }

  async update(
    userId: string,
    scheduleId: string,
    input: UpdateMedicationScheduleDto,
  ) {
    const schedule = await this.ownedSchedule(userId, scheduleId);
    if (schedule.status !== "ACTIVE") {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "SCHEDULE_NOT_ACTIVE",
        "Resume the schedule before changing its dose times.",
      );
    }
    const startDate = input.startDate ?? schedule.startDate;
    const endDate = input.openEnded
      ? undefined
      : (input.endDate ?? schedule.endDate ?? undefined);
    const times = input.times ?? (JSON.parse(schedule.timesJson) as string[]);
    const timezone = input.timezone ?? schedule.timezone;
    if (timezone !== schedule.medication.patientProfile.timezone) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "SCHEDULE_TIMEZONE_MISMATCH",
        "Update the patient profile timezone before changing the schedule timezone.",
      );
    }
    const recurrence = (input.recurrence ??
      schedule.recurrence) as ScheduleRecurrence;
    const daysOfWeek =
      input.daysOfWeek ?? (JSON.parse(schedule.daysOfWeekJson) as number[]);
    const excludedDates =
      input.excludedDates ??
      (JSON.parse(schedule.excludedDatesJson) as string[]);
    const generation = this.engine.generate({
      daysOfWeek,
      ...(endDate ? { endDate } : {}),
      excludedDates,
      horizonDays: schedule.generationHorizonDays,
      quantityUnit: schedule.medication.instructions!.quantityUnit,
      quantityValue: schedule.medication.instructions!.quantityValue,
      recurrence,
      startDate,
      times,
      timezone,
    });
    const revision = schedule.revision + 1;
    const now = new Date();
    await this.database.$transaction(async (transaction) => {
      const updated = await transaction.medicationSchedule.updateMany({
        data: {
          daysOfWeekJson: JSON.stringify(daysOfWeek),
          endDate: endDate ?? null,
          excludedDatesJson: JSON.stringify(excludedDates),
          generatedThroughDate: generation.generatedThroughDate,
          recurrence,
          revision,
          startDate,
          timesJson: JSON.stringify([...times].sort()),
          timezone,
          version: { increment: 1 },
        },
        where: {
          id: scheduleId,
          status: "ACTIVE",
          version: input.expectedVersion,
        },
      });
      if (updated.count !== 1) this.versionConflict();
      await transaction.doseOccurrence.updateMany({
        data: { status: "CANCELLED", version: { increment: 1 } },
        where: { plannedAt: { gt: now }, scheduleId, status: "SCHEDULED" },
      });
      await transaction.doseOccurrence.createMany({
        data: generation.occurrences
          .filter((occurrence) => occurrence.plannedAt > now)
          .map((occurrence) =>
            this.occurrenceData(schedule, occurrence, revision),
          ),
      });
    });
    return this.getSchedule(userId, scheduleId);
  }

  async pause(userId: string, scheduleId: string, input: ScheduleCommandDto) {
    await this.ownedSchedule(userId, scheduleId);
    await this.database.$transaction(async (transaction) => {
      const updated = await transaction.medicationSchedule.updateMany({
        data: { status: "PAUSED", version: { increment: 1 } },
        where: {
          id: scheduleId,
          status: "ACTIVE",
          version: input.expectedVersion,
        },
      });
      if (updated.count !== 1) this.versionConflict();
      await transaction.doseOccurrence.updateMany({
        data: { status: "CANCELLED", version: { increment: 1 } },
        where: {
          plannedAt: { gt: new Date() },
          scheduleId,
          status: "SCHEDULED",
        },
      });
    });
    return this.getSchedule(userId, scheduleId);
  }

  async resume(userId: string, scheduleId: string, input: ScheduleCommandDto) {
    const schedule = await this.ownedSchedule(userId, scheduleId);
    if (schedule.status === "ENDED") {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "SCHEDULE_ENDED",
        "An ended schedule cannot be resumed. Create a new reviewed schedule.",
      );
    }
    const generation = this.engine.generate({
      daysOfWeek: JSON.parse(schedule.daysOfWeekJson) as number[],
      ...(schedule.endDate ? { endDate: schedule.endDate } : {}),
      excludedDates: JSON.parse(schedule.excludedDatesJson) as string[],
      horizonDays: schedule.generationHorizonDays,
      quantityUnit: schedule.medication.instructions!.quantityUnit,
      quantityValue: schedule.medication.instructions!.quantityValue,
      recurrence: schedule.recurrence as ScheduleRecurrence,
      startDate: schedule.startDate,
      times: JSON.parse(schedule.timesJson) as string[],
      timezone: schedule.timezone,
    });
    const revision = schedule.revision + 1;
    const now = new Date();
    const future = generation.occurrences.filter(
      (occurrence) => occurrence.plannedAt > now,
    );
    if (future.length === 0) {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "SCHEDULE_PERIOD_ENDED",
        "This schedule has no future occurrences. Create a new schedule.",
      );
    }
    await this.database.$transaction(async (transaction) => {
      const updated = await transaction.medicationSchedule.updateMany({
        data: {
          generatedThroughDate: generation.generatedThroughDate,
          revision,
          status: "ACTIVE",
          version: { increment: 1 },
        },
        where: {
          id: scheduleId,
          status: "PAUSED",
          version: input.expectedVersion,
        },
      });
      if (updated.count !== 1) this.versionConflict();
      await transaction.doseOccurrence.createMany({
        data: future.map((occurrence) =>
          this.occurrenceData(schedule, occurrence, revision),
        ),
      });
    });
    return this.getSchedule(userId, scheduleId);
  }

  async end(userId: string, scheduleId: string, input: ScheduleCommandDto) {
    await this.ownedSchedule(userId, scheduleId);
    await this.database.$transaction(async (transaction) => {
      const updated = await transaction.medicationSchedule.updateMany({
        data: { status: "ENDED", version: { increment: 1 } },
        where: {
          id: scheduleId,
          status: { in: ["ACTIVE", "PAUSED"] },
          version: input.expectedVersion,
        },
      });
      if (updated.count !== 1) this.versionConflict();
      await transaction.doseOccurrence.updateMany({
        data: { status: "CANCELLED", version: { increment: 1 } },
        where: {
          plannedAt: { gt: new Date() },
          scheduleId,
          status: "SCHEDULED",
        },
      });
    });
    return this.getSchedule(userId, scheduleId);
  }

  private async getSchedule(userId: string, scheduleId: string) {
    const schedule = await this.ownedSchedule(userId, scheduleId);
    return this.response(this.scheduleView(schedule));
  }

  private ownedSchedule(userId: string, scheduleId: string) {
    return this.database.medicationSchedule
      .findFirst({
        include: {
          medication: { include: { instructions: true, patientProfile: true } },
        },
        where: {
          id: scheduleId,
          medication: { patientProfile: { ownerUserId: userId } },
        },
      })
      .then((schedule) => schedule ?? this.notFound());
  }

  private occurrenceData(
    schedule: Awaited<ReturnType<MedicationScheduleService["ownedSchedule"]>>,
    occurrence: ScheduleOccurrence,
    revision: number,
  ) {
    return {
      id: ulid(),
      medicationId: schedule.medicationId,
      patientProfileId: schedule.medication.patientProfileId,
      plannedAt: occurrence.plannedAt,
      plannedLocalDateTime: occurrence.plannedLocalDateTime,
      quantityUnit: occurrence.quantityUnit,
      quantityValue: occurrence.quantityValue,
      ruleRevision: revision,
      scheduleId: schedule.id,
      timezone: schedule.timezone,
    };
  }

  private async readableProfile(userId: string, profileId: string) {
    const profile = await this.database.patientProfile.findUnique({
      where: { id: profileId },
    });
    if (!profile) this.notFound();
    if (profile.ownerUserId === userId) {
      return { canViewDoseOutcomes: true, profile };
    }
    const invitation = await this.database.careInvitation.findFirst({
      where: {
        acceptedByUserId: userId,
        patientProfileId: profileId,
        status: "ACCEPTED",
      },
    });
    if (!invitation || !this.canViewPlan(invitation.permissionsJson)) {
      this.notFound();
    }
    return {
      canViewDoseOutcomes: this.canViewDoseOutcomes(invitation.permissionsJson),
      profile,
    };
  }

  private canViewPlan(permissionsJson: string): boolean {
    try {
      return (
        (JSON.parse(permissionsJson) as { canViewMedicationPlan?: boolean })
          .canViewMedicationPlan === true
      );
    } catch {
      return false;
    }
  }

  private canViewDoseOutcomes(permissionsJson: string): boolean {
    try {
      return (
        (JSON.parse(permissionsJson) as { canViewDoseOutcomes?: boolean })
          .canViewDoseOutcomes === true
      );
    } catch {
      return false;
    }
  }

  private scheduleView(schedule: {
    daysOfWeekJson: string;
    endDate: string | null;
    excludedDatesJson: string;
    generatedThroughDate: string;
    generationHorizonDays: number;
    id: string;
    medicationId: string;
    recurrence: string;
    revision: number;
    startDate: string;
    status: string;
    timesJson: string;
    timezone: string;
    timezonePolicy: string;
    version: number;
  }) {
    return {
      daysOfWeek: JSON.parse(schedule.daysOfWeekJson) as number[],
      endDate: schedule.endDate,
      excludedDates: JSON.parse(schedule.excludedDatesJson) as string[],
      generatedThroughDate: schedule.generatedThroughDate,
      generationHorizonDays: schedule.generationHorizonDays,
      id: schedule.id,
      medicationId: schedule.medicationId,
      recurrence: schedule.recurrence,
      revision: schedule.revision,
      startDate: schedule.startDate,
      status: schedule.status,
      times: JSON.parse(schedule.timesJson) as string[],
      timezone: schedule.timezone,
      timezonePolicy: schedule.timezonePolicy,
      version: schedule.version,
    };
  }

  private notFound(): never {
    throw new AuthError(
      HttpStatus.NOT_FOUND,
      "RESOURCE_NOT_FOUND",
      "The requested item was not found.",
    );
  }

  private versionConflict(): never {
    throw new AuthError(
      HttpStatus.CONFLICT,
      "SCHEDULE_VERSION_CONFLICT",
      "This schedule changed on another device. Refresh and try again.",
    );
  }

  private activeScheduleConflict(): never {
    throw new AuthError(
      HttpStatus.CONFLICT,
      "ACTIVE_SCHEDULE_EXISTS",
      "Edit, pause, or end the current schedule before creating another.",
    );
  }

  private previewHorizonDays(startDate: string, endDate?: string): number {
    if (!endDate) return 30;
    const start = new Date(`${startDate}T00:00:00.000Z`);
    const end = new Date(`${endDate}T00:00:00.000Z`);
    const days = Math.floor((end.getTime() - start.getTime()) / 86_400_000) + 1;
    if (days > 366) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "SCHEDULE_INVALID",
        "Schedule previews are limited to 366 days.",
      );
    }
    return Math.max(1, days);
  }

  private daysInclusive(startDate: string, endDate: string): number {
    const start = new Date(`${startDate}T00:00:00.000Z`);
    const end = new Date(`${endDate}T00:00:00.000Z`);
    return Math.floor((end.getTime() - start.getTime()) / 86_400_000) + 1;
  }

  private addDays(value: string, days: number): string {
    const date = new Date(`${value}T00:00:00.000Z`);
    date.setUTCDate(date.getUTCDate() + days);
    return date.toISOString().slice(0, 10);
  }

  private localDateInTimezone(timezone: string): string {
    const parts = new Intl.DateTimeFormat("en-CA", {
      day: "2-digit",
      month: "2-digit",
      timeZone: timezone,
      year: "numeric",
    }).formatToParts(new Date());
    const values = Object.fromEntries(
      parts
        .filter((part) => part.type !== "literal")
        .map((part) => [part.type, part.value]),
    );
    return `${values.year}-${values.month}-${values.day}`;
  }

  private isUniqueConstraint(error: unknown): boolean {
    return (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      (error as { code?: unknown }).code === "P2002"
    );
  }

  private response(data: unknown) {
    return { data, meta: { requestId: `req_${ulid()}` } };
  }
}
