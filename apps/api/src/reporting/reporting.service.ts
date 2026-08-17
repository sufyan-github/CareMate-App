import { HttpStatus, Injectable } from "@nestjs/common";
import { ulid } from "ulid";

import { AuthError } from "../auth/auth-error.js";
import { DatabaseService } from "../database/database.service.js";
import { DoseLifecycleService } from "../dose-lifecycle/dose-lifecycle.service.js";
import type { IndicatorWindowDto } from "./reporting.dto.js";

interface IndicatorCounts {
  cancelledExcluded: number;
  futureExcluded: number;
  lateConfirmed: number;
  missed: number;
  onTimeConfirmed: number;
  skipped: number;
  unresolved: number;
}

interface IndicatorBucket extends IndicatorCounts {
  eligibleCompleted: number;
  eligibleConfirmed: number;
  percentage: number | null;
}

interface IndicatorOccurrence {
  medication: { displayName: string; id: string };
  plannedAt: Date;
  plannedLocalDateTime: string;
  status: string;
  timingClassification: string | null;
}

@Injectable()
export class ReportingService {
  constructor(
    private readonly database: DatabaseService,
    private readonly doseLifecycle: DoseLifecycleService,
  ) {}

  async indicator(
    userId: string,
    profileId: string,
    window: IndicatorWindowDto,
  ) {
    const profile = await this.authorizedProfile(userId, profileId);
    this.validateWindow(window);
    await this.doseLifecycle.evaluateWindow(profileId, window.from, window.to);
    const occurrences = await this.database.doseOccurrence.findMany({
      include: { medication: { select: { displayName: true, id: true } } },
      orderBy: { plannedAt: "asc" },
      where: {
        patientProfileId: profileId,
        plannedLocalDateTime: {
          gte: `${window.from}T00:00`,
          lte: `${window.to}T23:59`,
        },
      },
    });
    const now = new Date();
    const totals = this.summarize(occurrences, now);
    const daily = this.group(
      occurrences,
      (occurrence) => occurrence.plannedLocalDateTime.slice(0, 10),
      now,
    ).map(([date, summary]) => ({ date, ...summary }));
    const medications = this.group(
      occurrences,
      (occurrence) => occurrence.medication.id,
      now,
    ).map(([medicationId, summary]) => ({
      medicationId,
      medicationName: occurrences.find(
        (occurrence) => occurrence.medication.id === medicationId,
      )!.medication.displayName,
      ...summary,
    }));

    return this.response({
      appBased: true,
      counts: {
        cancelledExcluded: totals.cancelledExcluded,
        futureExcluded: totals.futureExcluded,
        lateConfirmed: totals.lateConfirmed,
        missed: totals.missed,
        onTimeConfirmed: totals.onTimeConfirmed,
        skipped: totals.skipped,
        unresolved: totals.unresolved,
      },
      daily,
      denominator: totals.eligibleCompleted,
      disclaimer:
        "This is an app-based summary of self-reported outcomes. It is not a clinical adherence measure.",
      eligibility: {
        denominator:
          "Confirmed, skipped, or missed planned doses whose local date is in the selected period.",
        exclusions:
          "Cancelled and future doses are excluded. Due doses without an outcome are shown as unresolved until their response deadline passes.",
        numerator: "Confirmed planned doses in the denominator.",
      },
      label: "App-based adherence indicator",
      medications,
      numerator: totals.eligibleConfirmed,
      percentage: totals.percentage,
      period: {
        from: window.from,
        timezone: profile.timezone,
        to: window.to,
      },
      selfReported: true,
    });
  }

  private summarize(
    occurrences: IndicatorOccurrence[],
    now: Date,
  ): IndicatorBucket {
    const counts: IndicatorCounts = {
      cancelledExcluded: 0,
      futureExcluded: 0,
      lateConfirmed: 0,
      missed: 0,
      onTimeConfirmed: 0,
      skipped: 0,
      unresolved: 0,
    };
    for (const occurrence of occurrences) {
      if (occurrence.status === "CANCELLED") {
        counts.cancelledExcluded += 1;
      } else if (occurrence.plannedAt > now) {
        counts.futureExcluded += 1;
      } else if (occurrence.status === "CONFIRMED") {
        if (occurrence.timingClassification === "LATE") {
          counts.lateConfirmed += 1;
        } else {
          counts.onTimeConfirmed += 1;
        }
      } else if (occurrence.status === "SKIPPED") {
        counts.skipped += 1;
      } else if (occurrence.status === "MISSED") {
        counts.missed += 1;
      } else {
        counts.unresolved += 1;
      }
    }
    const eligibleConfirmed = counts.onTimeConfirmed + counts.lateConfirmed;
    const eligibleCompleted =
      eligibleConfirmed + counts.skipped + counts.missed;
    return {
      ...counts,
      eligibleCompleted,
      eligibleConfirmed,
      percentage:
        eligibleCompleted === 0
          ? null
          : Math.round((eligibleConfirmed / eligibleCompleted) * 1000) / 10,
    };
  }

  private group(
    occurrences: IndicatorOccurrence[],
    keyFor: (occurrence: IndicatorOccurrence) => string,
    now: Date,
  ): Array<[string, IndicatorBucket]> {
    const grouped = new Map<string, IndicatorOccurrence[]>();
    for (const occurrence of occurrences) {
      const key = keyFor(occurrence);
      grouped.set(key, [...(grouped.get(key) ?? []), occurrence]);
    }
    return [...grouped.entries()].map(([key, values]) => [
      key,
      this.summarize(values, now),
    ]);
  }

  private validateWindow(window: IndicatorWindowDto): void {
    const from = new Date(`${window.from}T00:00:00.000Z`);
    const to = new Date(`${window.to}T00:00:00.000Z`);
    const days = (to.getTime() - from.getTime()) / 86_400_000;
    if (
      Number.isNaN(from.getTime()) ||
      Number.isNaN(to.getTime()) ||
      days < 0 ||
      days > 365
    ) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "INDICATOR_WINDOW_INVALID",
        "Choose a valid reporting period of up to 366 days.",
      );
    }
  }

  private async authorizedProfile(userId: string, profileId: string) {
    const profile = await this.database.patientProfile.findUnique({
      where: { id: profileId },
    });
    if (!profile) this.notFound();
    if (profile.ownerUserId === userId) return profile;
    const relationship = await this.database.careInvitation.findFirst({
      where: {
        acceptedByUserId: userId,
        patientProfileId: profileId,
        status: "ACCEPTED",
      },
    });
    if (!relationship) this.notFound();
    try {
      const permissions = JSON.parse(relationship.permissionsJson) as {
        canViewDoseOutcomes?: boolean;
        canViewMedicationPlan?: boolean;
      };
      if (
        permissions.canViewMedicationPlan === true &&
        permissions.canViewDoseOutcomes === true
      ) {
        return profile;
      }
    } catch {
      // Invalid historic permission data is denied.
    }
    this.notFound();
  }

  private notFound(): never {
    throw new AuthError(
      HttpStatus.NOT_FOUND,
      "RESOURCE_NOT_FOUND",
      "The requested item was not found.",
    );
  }

  private response(data: unknown) {
    return { data, meta: { requestId: `req_${ulid()}` } };
  }
}
