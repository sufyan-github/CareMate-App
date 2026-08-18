import {
  HttpStatus,
  Injectable,
  type OnModuleDestroy,
  type OnModuleInit,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { ulid } from "ulid";

import { AuthError } from "../auth/auth-error.js";
import { CaregiverAlertsService } from "../caregiver-alerts/caregiver-alerts.service.js";
import { DatabaseService } from "../database/database.service.js";
import type { DoseCommandDto } from "./dose-lifecycle.dto.js";

interface DoseCommandResult {
  confirmedAt: string | null;
  id: string;
  missedAt: string | null;
  reminderSentAt: string | null;
  responseDueAt: string | null;
  snoozeCount: number;
  snoozedUntil: string | null;
  status: string;
  timingClassification: string | null;
  version: number;
}

interface AppliedDoseCommand {
  alreadyApplied: boolean;
  data: DoseCommandResult;
}

@Injectable()
export class DoseLifecycleService implements OnModuleInit, OnModuleDestroy {
  private repairTimer: NodeJS.Timeout | undefined;
  private repairRunning = false;

  constructor(
    private readonly config: ConfigService,
    private readonly database: DatabaseService,
    private readonly caregiverAlerts: CaregiverAlertsService,
  ) {}

  onModuleInit(): void {
    this.repairTimer = setInterval(() => {
      void this.repairOverdueOccurrences();
    }, this.repairIntervalMilliseconds());
    this.repairTimer.unref();
  }

  onModuleDestroy(): void {
    if (this.repairTimer) clearInterval(this.repairTimer);
  }

  async get(userId: string, occurrenceId: string) {
    await this.readableOccurrence(userId, occurrenceId, false);
    await this.evaluateOccurrenceState(occurrenceId);
    const occurrence = await this.readableOccurrence(
      userId,
      occurrenceId,
      true,
    );
    return this.response({
      ...this.view(occurrence),
      events: occurrence.events.map((event) => ({
        actorUserId: event.actorUserId,
        clientAt: event.clientAt?.toISOString() ?? null,
        clientMutationId: event.clientMutationId,
        eventType: event.eventType,
        id: event.id,
        metadata: JSON.parse(event.metadataJson) as unknown,
        serverAt: event.serverAt.toISOString(),
      })),
    });
  }

  async evaluateWindow(
    patientProfileId: string,
    from: string,
    to: string,
  ): Promise<void> {
    const occurrences = await this.database.doseOccurrence.findMany({
      select: { id: true },
      where: {
        patientProfileId,
        plannedLocalDateTime: {
          gte: `${from}T00:00`,
          lte: `${to}T23:59`,
        },
        status: { in: ["SCHEDULED", "REMINDER_SENT", "SNOOZED"] },
      },
    });
    for (const occurrence of occurrences) {
      await this.evaluateOccurrenceState(occurrence.id);
    }
  }

  async command(
    userId: string,
    authSessionId: string,
    occurrenceId: string,
    input: DoseCommandDto,
  ) {
    try {
      const data = await this.database.$transaction(async (transaction) => {
        const prior = await transaction.doseEvent.findUnique({
          where: { clientMutationId: input.clientMutationId },
        });
        if (prior) {
          this.assertMutationOwner(prior, userId, occurrenceId);
          return {
            alreadyApplied: true,
            data: JSON.parse(prior.resultJson!) as DoseCommandResult,
          } satisfies AppliedDoseCommand;
        }

        const occurrence = await transaction.doseOccurrence.findFirst({
          include: { medication: { include: { patientProfile: true } } },
          where: {
            id: occurrenceId,
            medication: { patientProfile: { ownerUserId: userId } },
          },
        });
        if (!occurrence) this.notFound();
        if (occurrence.version !== input.expectedVersion)
          this.versionConflict();
        const authSession = await transaction.authSession.findFirst({
          select: { installationId: true },
          where: { id: authSessionId, userId },
        });
        if (!authSession) this.notFound();
        const nextEventSequence =
          (await transaction.doseEvent.count({ where: { occurrenceId } })) + 1;
        const now = new Date();
        const clientAt = new Date(input.clientAt);
        if (occurrence.status === "SCHEDULED" && now < occurrence.plannedAt) {
          throw new AuthError(
            HttpStatus.CONFLICT,
            "DOSE_NOT_DUE",
            "This dose is not due yet.",
          );
        }
        if (input.command === "SNOOZE") {
          if (!input.payload?.snoozeMinutes) {
            throw new AuthError(
              HttpStatus.BAD_REQUEST,
              "SNOOZE_DURATION_REQUIRED",
              "Choose how many minutes to snooze this dose.",
            );
          }
          if (!["SCHEDULED", "REMINDER_SENT"].includes(occurrence.status)) {
            this.invalidTransition(occurrence.status, input.command);
          }
          if (occurrence.snoozeCount >= 3) {
            throw new AuthError(
              HttpStatus.CONFLICT,
              "SNOOZE_LIMIT_REACHED",
              "This dose has reached its snooze limit.",
            );
          }
          const snoozedUntil = new Date(
            now.getTime() + input.payload.snoozeMinutes * 60_000,
          );
          const responseDueAt = new Date(
            snoozedUntil.getTime() +
              occurrence.medication.patientProfile.missedDoseGraceMinutes *
                60_000,
          );
          const reminderSentAt = occurrence.reminderSentAt ?? now;
          const updated = await transaction.doseOccurrence.updateMany({
            data: {
              reminderSentAt,
              responseDueAt,
              snoozeCount: { increment: 1 },
              snoozedUntil,
              status: "SNOOZED",
              version: { increment: 1 },
            },
            where: {
              id: occurrenceId,
              status: occurrence.status,
              version: input.expectedVersion,
            },
          });
          if (updated.count !== 1) this.versionConflict();
          const result: DoseCommandResult = {
            confirmedAt: null,
            id: occurrenceId,
            missedAt: occurrence.missedAt?.toISOString() ?? null,
            reminderSentAt: reminderSentAt.toISOString(),
            responseDueAt: responseDueAt.toISOString(),
            snoozeCount: occurrence.snoozeCount + 1,
            snoozedUntil: snoozedUntil.toISOString(),
            status: "SNOOZED",
            timingClassification: null,
            version: occurrence.version + 1,
          };
          await transaction.doseEvent.create({
            data: {
              actorUserId: userId,
              clientAt,
              clientMutationId: input.clientMutationId,
              eventType: "SNOOZED",
              id: ulid(),
              metadataJson: JSON.stringify({
                snoozeMinutes: input.payload.snoozeMinutes,
              }),
              occurrenceId,
              resultJson: JSON.stringify(result),
              sequence: nextEventSequence,
            },
          });
          return { alreadyApplied: false, data: result };
        }

        if (input.command === "SKIP") {
          if (
            !["SCHEDULED", "REMINDER_SENT", "SNOOZED"].includes(
              occurrence.status,
            )
          ) {
            this.invalidTransition(occurrence.status, input.command);
          }
          const updated = await transaction.doseOccurrence.updateMany({
            data: {
              snoozedUntil: null,
              status: "SKIPPED",
              version: { increment: 1 },
            },
            where: {
              id: occurrenceId,
              status: occurrence.status,
              version: input.expectedVersion,
            },
          });
          if (updated.count !== 1) this.versionConflict();
          const result: DoseCommandResult = {
            confirmedAt: null,
            id: occurrenceId,
            missedAt: occurrence.missedAt?.toISOString() ?? null,
            reminderSentAt: occurrence.reminderSentAt?.toISOString() ?? null,
            responseDueAt: occurrence.responseDueAt?.toISOString() ?? null,
            snoozeCount: occurrence.snoozeCount,
            snoozedUntil: null,
            status: "SKIPPED",
            timingClassification: null,
            version: occurrence.version + 1,
          };
          await transaction.doseEvent.create({
            data: {
              actorUserId: userId,
              clientAt,
              clientMutationId: input.clientMutationId,
              eventType: "SKIPPED",
              id: ulid(),
              metadataJson: JSON.stringify({
                ...(input.payload?.reason
                  ? { reason: input.payload.reason }
                  : {}),
              }),
              occurrenceId,
              resultJson: JSON.stringify(result),
              sequence: nextEventSequence,
            },
          });
          return { alreadyApplied: false, data: result };
        }

        if (
          !["SCHEDULED", "REMINDER_SENT", "SNOOZED", "MISSED"].includes(
            occurrence.status,
          )
        ) {
          this.invalidTransition(occurrence.status, input.command);
        }
        const responseDueAt =
          occurrence.responseDueAt ??
          new Date(
            occurrence.plannedAt.getTime() +
              occurrence.medication.patientProfile.missedDoseGraceMinutes *
                60_000,
          );
        const becameMissed =
          !occurrence.missedAt &&
          ["SCHEDULED", "REMINDER_SENT", "SNOOZED"].includes(
            occurrence.status,
          ) &&
          responseDueAt < now;
        const missedAt = occurrence.missedAt ?? (becameMissed ? now : null);
        const timingClassification = missedAt ? "LATE" : "ON_TIME";
        const versionIncrement = becameMissed ? 2 : 1;
        const updated = await transaction.doseOccurrence.updateMany({
          data: {
            confirmedAt: now,
            missedAt,
            responseDueAt,
            snoozedUntil: null,
            status: "CONFIRMED",
            timingClassification,
            version: { increment: versionIncrement },
          },
          where: {
            id: occurrenceId,
            status: occurrence.status,
            version: input.expectedVersion,
          },
        });
        if (updated.count !== 1) this.versionConflict();

        if (becameMissed) {
          await transaction.doseEvent.create({
            data: {
              eventType: "MISSED",
              id: ulid(),
              metadataJson: JSON.stringify({
                meaning: "NO_OUTCOME_RECORDED_BY_DEADLINE",
              }),
              occurrenceId,
              sequence: nextEventSequence,
            },
          });
        }

        await transaction.doseConfirmation.create({
          data: {
            actorUserId: userId,
            authSessionId,
            clientAt,
            confirmedAt: now,
            deviceInstallationId: authSession.installationId,
            id: ulid(),
            occurrenceId,
            timingClassification,
          },
        });
        const inventoryPosition =
          await transaction.inventoryPosition.findUniqueOrThrow({
            where: { medicationId: occurrence.medicationId },
          });
        await transaction.stockAdjustment.create({
          data: {
            actorUserId: userId,
            delta: -occurrence.quantityValue,
            id: ulid(),
            idempotencyKey: `dose-confirmation:${occurrenceId}`,
            inventoryPositionId: inventoryPosition.id,
            occurrenceId,
            reason: "CONFIRMED_CONSUMPTION",
          },
        });
        const result: DoseCommandResult = {
          confirmedAt: now.toISOString(),
          id: occurrenceId,
          missedAt: missedAt?.toISOString() ?? null,
          reminderSentAt: occurrence.reminderSentAt?.toISOString() ?? null,
          responseDueAt: responseDueAt.toISOString(),
          snoozeCount: occurrence.snoozeCount,
          snoozedUntil: null,
          status: "CONFIRMED",
          timingClassification,
          version: occurrence.version + versionIncrement,
        };
        await transaction.doseEvent.create({
          data: {
            actorUserId: userId,
            clientAt,
            clientMutationId: input.clientMutationId,
            eventType: "CONFIRMED",
            id: ulid(),
            occurrenceId,
            resultJson: JSON.stringify(result),
            sequence: nextEventSequence + (becameMissed ? 1 : 0),
          },
        });
        return { alreadyApplied: false, data: result };
      });
      if (data.data.status === "CONFIRMED" && data.data.missedAt) {
        await this.caregiverAlerts.fanOutForOccurrence(occurrenceId);
        await this.caregiverAlerts.resolveForOccurrence(
          occurrenceId,
          new Date(data.data.confirmedAt!),
        );
      }
      return this.response(data.data, data.alreadyApplied);
    } catch (error) {
      const prior = await this.database.doseEvent.findUnique({
        where: { clientMutationId: input.clientMutationId },
      });
      if (prior) {
        this.assertMutationOwner(prior, userId, occurrenceId);
        return this.response(
          JSON.parse(prior.resultJson!) as DoseCommandResult,
          true,
        );
      }
      throw error;
    }
  }

  private async evaluateOccurrenceState(occurrenceId: string): Promise<void> {
    const becameMissed = await this.database.$transaction(
      async (transaction) => {
        const occurrence = await transaction.doseOccurrence.findUnique({
          include: { patientProfile: true },
          where: { id: occurrenceId },
        });
        if (!occurrence) return false;
        const now = new Date();
        const nextEventSequence =
          (await transaction.doseEvent.count({ where: { occurrenceId } })) + 1;
        const responseDueAt =
          occurrence.responseDueAt ??
          new Date(
            occurrence.plannedAt.getTime() +
              occurrence.patientProfile.missedDoseGraceMinutes * 60_000,
          );
        if (
          ["SCHEDULED", "REMINDER_SENT", "SNOOZED"].includes(
            occurrence.status,
          ) &&
          responseDueAt < now
        ) {
          const updated = await transaction.doseOccurrence.updateMany({
            data: {
              missedAt: now,
              responseDueAt,
              snoozedUntil: null,
              status: "MISSED",
              version: { increment: 1 },
            },
            where: {
              id: occurrenceId,
              status: occurrence.status,
              version: occurrence.version,
            },
          });
          if (updated.count === 0) return false;
          await transaction.doseEvent.create({
            data: {
              eventType: "MISSED",
              id: ulid(),
              metadataJson: JSON.stringify({
                meaning: "NO_OUTCOME_RECORDED_BY_DEADLINE",
              }),
              occurrenceId,
              sequence: nextEventSequence,
            },
          });
          return true;
        }
        if (
          occurrence.status !== "SNOOZED" ||
          !occurrence.snoozedUntil ||
          occurrence.snoozedUntil > now
        ) {
          return false;
        }
        const updated = await transaction.doseOccurrence.updateMany({
          data: {
            reminderSentAt: now,
            snoozedUntil: null,
            status: "REMINDER_SENT",
            version: { increment: 1 },
          },
          where: {
            id: occurrenceId,
            snoozedUntil: occurrence.snoozedUntil,
            status: "SNOOZED",
            version: occurrence.version,
          },
        });
        if (updated.count === 0) return false;
        await transaction.doseEvent.create({
          data: {
            eventType: "REMINDER_SENT",
            id: ulid(),
            metadataJson: JSON.stringify({ source: "SNOOZE_EXPIRED" }),
            occurrenceId,
            sequence: nextEventSequence,
          },
        });
        return false;
      },
    );
    if (becameMissed) {
      await this.caregiverAlerts.fanOutForOccurrence(occurrenceId);
    }
  }

  private async repairOverdueOccurrences(): Promise<void> {
    if (this.repairRunning) return;
    this.repairRunning = true;
    try {
      const now = new Date();
      const plannedDeadline = new Date(now.getTime() - 5 * 60_000);
      const overdue = await this.database.doseOccurrence.findMany({
        select: { id: true },
        where: {
          OR: [
            { responseDueAt: { lt: now } },
            { plannedAt: { lt: plannedDeadline }, responseDueAt: null },
          ],
          status: { in: ["SCHEDULED", "REMINDER_SENT", "SNOOZED"] },
        },
      });
      for (const occurrence of overdue) {
        await this.evaluateOccurrenceState(occurrence.id);
      }
    } finally {
      this.repairRunning = false;
    }
  }

  async simulateMiss(
    userId: string,
    patientProfileId: string,
    minutesLate: number,
  ) {
    if (
      this.config.get<string>("COMPETITION_DEMO") !== "true" &&
      this.config.get<string>("NODE_ENV") !== "test"
    ) {
      this.notFound();
    }
    const profile = await this.database.patientProfile.findFirst({
      where: { id: patientProfileId, ownerUserId: userId },
    });
    if (!profile) this.notFound();
    const occurrence = await this.database.doseOccurrence.findFirst({
      orderBy: { plannedAt: "desc" },
      where: {
        patientProfileId,
        status: { in: ["SCHEDULED", "REMINDER_SENT", "SNOOZED"] },
      },
    });
    if (!occurrence) {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "DEMO_OCCURRENCE_UNAVAILABLE",
        "No unresolved demo dose is available to mark missed.",
      );
    }
    const now = new Date();
    const plannedAt = new Date(now.getTime() - minutesLate * 60_000);
    const plannedLocalDateTime = await this.uniqueDemoLocalDateTime(
      occurrence.id,
      occurrence.scheduleId,
      occurrence.ruleRevision,
      this.localDateTime(plannedAt, profile.timezone),
    );
    await this.database.doseOccurrence.update({
      data: {
        missedAt: null,
        plannedAt,
        plannedLocalDateTime,
        reminderSentAt: plannedAt,
        responseDueAt: new Date(now.getTime() - 1_000),
        snoozedUntil: null,
        status: "REMINDER_SENT",
        version: { increment: 1 },
      },
      where: { id: occurrence.id },
    });
    await this.evaluateOccurrenceState(occurrence.id);
    const updated = await this.database.doseOccurrence.findUniqueOrThrow({
      where: { id: occurrence.id },
    });
    return this.response({
      id: updated.id,
      missedAt: updated.missedAt?.toISOString() ?? null,
      plannedAt: updated.plannedAt.toISOString(),
      status: updated.status,
      version: updated.version,
    });
  }

  private async readableOccurrence(
    userId: string,
    occurrenceId: string,
    includeEvents: boolean,
  ) {
    const occurrence = await this.database.doseOccurrence.findFirst({
      include: {
        events: includeEvents ? { orderBy: { sequence: "asc" } } : false,
        medication: { include: { patientProfile: true } },
      },
      where: {
        id: occurrenceId,
      },
    });
    if (!occurrence) this.notFound();
    if (occurrence.medication.patientProfile.ownerUserId === userId) {
      return occurrence;
    }
    const relationship = await this.database.careInvitation.findFirst({
      where: {
        acceptedByUserId: userId,
        patientProfileId: occurrence.patientProfileId,
        status: "ACCEPTED",
      },
    });
    if (
      !relationship ||
      !this.canViewDoseOutcomes(relationship.permissionsJson)
    ) {
      this.notFound();
    }
    return occurrence;
  }

  private canViewDoseOutcomes(permissionsJson: string): boolean {
    try {
      const permissions = JSON.parse(permissionsJson) as {
        canViewDoseOutcomes?: boolean;
        canViewMedicationPlan?: boolean;
      };
      return (
        permissions.canViewMedicationPlan === true &&
        permissions.canViewDoseOutcomes === true
      );
    } catch {
      return false;
    }
  }

  private view(occurrence: {
    confirmedAt: Date | null;
    id: string;
    missedAt: Date | null;
    reminderSentAt: Date | null;
    responseDueAt: Date | null;
    snoozeCount: number;
    snoozedUntil: Date | null;
    status: string;
    timingClassification: string | null;
    version: number;
  }): DoseCommandResult {
    return {
      confirmedAt: occurrence.confirmedAt?.toISOString() ?? null,
      id: occurrence.id,
      missedAt: occurrence.missedAt?.toISOString() ?? null,
      reminderSentAt: occurrence.reminderSentAt?.toISOString() ?? null,
      responseDueAt: occurrence.responseDueAt?.toISOString() ?? null,
      snoozeCount: occurrence.snoozeCount,
      snoozedUntil: occurrence.snoozedUntil?.toISOString() ?? null,
      status: occurrence.status,
      timingClassification: occurrence.timingClassification,
      version: occurrence.version,
    };
  }

  private assertMutationOwner(
    event: { actorUserId: string | null; occurrenceId: string },
    userId: string,
    occurrenceId: string,
  ): void {
    if (event.actorUserId !== userId || event.occurrenceId !== occurrenceId) {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "CLIENT_MUTATION_ID_REUSED",
        "This device action identifier was already used for another dose.",
      );
    }
  }

  private invalidTransition(status: string, command: string): never {
    throw new AuthError(
      HttpStatus.CONFLICT,
      "DOSE_TRANSITION_INVALID",
      `A ${command.toLowerCase()} action is not allowed while this dose is ${status.toLowerCase()}.`,
    );
  }

  private versionConflict(): never {
    throw new AuthError(
      HttpStatus.CONFLICT,
      "DOSE_VERSION_CONFLICT",
      "This dose changed on another device. Refresh and try again.",
    );
  }

  private notFound(): never {
    throw new AuthError(
      HttpStatus.NOT_FOUND,
      "RESOURCE_NOT_FOUND",
      "The requested item was not found.",
    );
  }

  private repairIntervalMilliseconds(): number {
    const configured = Number(
      this.config.get<string>("DOSE_REPAIR_INTERVAL_SECONDS"),
    );
    const seconds =
      Number.isInteger(configured) && configured >= 15 && configured <= 3600
        ? configured
        : 60;
    return seconds * 1_000;
  }

  private localDateTime(value: Date, timezone: string): string {
    const values = Object.fromEntries(
      new Intl.DateTimeFormat("en-CA", {
        day: "2-digit",
        hour: "2-digit",
        hourCycle: "h23",
        minute: "2-digit",
        month: "2-digit",
        timeZone: timezone,
        year: "numeric",
      })
        .formatToParts(value)
        .filter((part) => part.type !== "literal")
        .map((part) => [part.type, part.value]),
    );
    return `${values.year}-${values.month}-${values.day}T${values.hour}:${values.minute}`;
  }

  private async uniqueDemoLocalDateTime(
    occurrenceId: string,
    scheduleId: string,
    ruleRevision: number,
    base: string,
  ): Promise<string> {
    for (let second = 0; second < 60; second += 1) {
      const candidate = `${base}:${second.toString().padStart(2, "0")}`;
      const conflict = await this.database.doseOccurrence.findFirst({
        select: { id: true },
        where: {
          id: { not: occurrenceId },
          plannedLocalDateTime: candidate,
          ruleRevision,
          scheduleId,
        },
      });
      if (!conflict) return candidate;
    }
    throw new AuthError(
      HttpStatus.CONFLICT,
      "DEMO_OCCURRENCE_TIME_CONFLICT",
      "The demo schedule has too many occurrences in the selected minute.",
    );
  }

  private response(data: unknown, alreadyApplied = false) {
    return {
      data,
      meta: { alreadyApplied, requestId: `req_${ulid()}` },
    };
  }
}
