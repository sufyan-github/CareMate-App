import { HttpStatus, Injectable } from "@nestjs/common";
import { ulid } from "ulid";

import { AuthError } from "../auth/auth-error.js";
import { DatabaseService } from "../database/database.service.js";
import type {
  CreateStockAdjustmentDto,
  UpdateInventoryPositionDto,
} from "./inventory.dto.js";

@Injectable()
export class InventoryService {
  constructor(private readonly database: DatabaseService) {}

  async list(userId: string, profileId: string) {
    await this.authorizeProfile(userId, profileId, false);
    const positions = await this.database.inventoryPosition.findMany({
      include: {
        adjustments: { orderBy: { createdAt: "desc" } },
        medication: true,
      },
      orderBy: { medication: { displayName: "asc" } },
      where: { patientProfileId: profileId },
    });
    const data = await Promise.all(
      positions.map((position) => this.positionView(position)),
    );
    return this.response(data);
  }

  async createAdjustment(
    userId: string,
    positionId: string,
    input: CreateStockAdjustmentDto,
  ) {
    if (input.delta === 0) {
      throw new AuthError(
        HttpStatus.BAD_REQUEST,
        "STOCK_ADJUSTMENT_ZERO",
        "Enter a stock change greater or less than zero.",
      );
    }
    const existing = await this.database.stockAdjustment.findUnique({
      where: { idempotencyKey: input.idempotencyKey },
    });
    if (existing) {
      if (existing.inventoryPositionId !== positionId) {
        throw new AuthError(
          HttpStatus.CONFLICT,
          "IDEMPOTENCY_KEY_REUSED",
          "This stock action identifier was already used.",
        );
      }
      return this.getPosition(userId, positionId, true);
    }

    const position = await this.authorizePosition(userId, positionId, true);
    if (position.quantityUnit !== input.quantityUnit.trim().toUpperCase()) {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "INVENTORY_UNIT_MISMATCH",
        `Stock for this medicine is recorded in ${position.quantityUnit}.`,
      );
    }
    await this.database.stockAdjustment.create({
      data: {
        actorUserId: userId,
        delta: input.delta,
        id: ulid(),
        idempotencyKey: input.idempotencyKey,
        inventoryPositionId: positionId,
        note: input.note?.trim() || null,
        reason: input.reason,
      },
    });
    return this.getPosition(userId, positionId, false);
  }

  async update(
    userId: string,
    positionId: string,
    input: UpdateInventoryPositionDto,
  ) {
    await this.authorizePosition(userId, positionId, true);
    const updated = await this.database.inventoryPosition.updateMany({
      data: {
        lowStockThreshold: input.lowStockThreshold,
        version: { increment: 1 },
      },
      where: { id: positionId, version: input.expectedVersion },
    });
    if (updated.count !== 1) {
      throw new AuthError(
        HttpStatus.CONFLICT,
        "INVENTORY_VERSION_CONFLICT",
        "This stock setting changed on another device. Refresh and try again.",
      );
    }
    return this.getPosition(userId, positionId, false);
  }

  private async getPosition(
    userId: string,
    positionId: string,
    alreadyApplied: boolean,
  ) {
    const position = await this.authorizePosition(userId, positionId, false);
    const full = await this.database.inventoryPosition.findUniqueOrThrow({
      include: {
        adjustments: { orderBy: { createdAt: "desc" } },
        medication: true,
      },
      where: { id: position.id },
    });
    return this.response(await this.positionView(full), alreadyApplied);
  }

  private async positionView(position: {
    adjustments: Array<{
      createdAt: Date;
      delta: number;
      id: string;
      note: string | null;
      occurrenceId: string | null;
      reason: string;
    }>;
    id: string;
    lowStockThreshold: number;
    medication: { displayName: string; id: string };
    patientProfileId: string;
    quantityUnit: string;
    version: number;
  }) {
    const estimatedQuantity = position.adjustments.reduce(
      (total, adjustment) => total + adjustment.delta,
      0,
    );
    const future = await this.database.doseOccurrence.findMany({
      orderBy: { plannedAt: "asc" },
      select: { plannedAt: true, quantityValue: true },
      where: {
        medicationId: position.medication.id,
        plannedAt: { gt: new Date() },
        status: { in: ["SCHEDULED", "REMINDER_SENT", "SNOOZED"] },
      },
    });
    let plannedConsumption = 0;
    let projectedRunOutAt: Date | null =
      estimatedQuantity <= 0 ? new Date() : null;
    if (estimatedQuantity > 0) {
      for (const occurrence of future) {
        plannedConsumption += occurrence.quantityValue;
        if (plannedConsumption >= estimatedQuantity) {
          projectedRunOutAt = occurrence.plannedAt;
          break;
        }
      }
    }
    const millisecondsPerDay = 86_400_000;
    const estimatedDaysRemaining = projectedRunOutAt
      ? Math.max(
          0,
          Math.ceil(
            (projectedRunOutAt.getTime() - Date.now()) / millisecondsPerDay,
          ),
        )
      : null;
    return {
      adjustments: position.adjustments.map((adjustment) => ({
        createdAt: adjustment.createdAt.toISOString(),
        delta: adjustment.delta,
        id: adjustment.id,
        note: adjustment.note,
        occurrenceId: adjustment.occurrenceId,
        reason: adjustment.reason,
      })),
      estimatedDaysRemaining,
      estimatedQuantity,
      forecastThrough: future.at(-1)?.plannedAt.toISOString() ?? null,
      id: position.id,
      isLowStock: estimatedQuantity <= position.lowStockThreshold,
      lowStockThreshold: position.lowStockThreshold,
      medicationId: position.medication.id,
      medicationName: position.medication.displayName,
      patientProfileId: position.patientProfileId,
      projectedRunOutAt: projectedRunOutAt?.toISOString() ?? null,
      quantityUnit: position.quantityUnit,
      version: position.version,
    };
  }

  private async authorizePosition(
    userId: string,
    positionId: string,
    manage: boolean,
  ) {
    const position = await this.database.inventoryPosition.findUnique({
      include: { patientProfile: true },
      where: { id: positionId },
    });
    if (!position) this.notFound();
    await this.authorizeProfile(userId, position.patientProfileId, manage);
    return position;
  }

  private async authorizeProfile(
    userId: string,
    profileId: string,
    manage: boolean,
  ): Promise<void> {
    const profile = await this.database.patientProfile.findUnique({
      where: { id: profileId },
    });
    if (!profile) this.notFound();
    if (profile.ownerUserId === userId) return;
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
        canManageInventory?: boolean;
        canViewInventory?: boolean;
      };
      if (
        (manage && permissions.canManageInventory === true) ||
        (!manage &&
          (permissions.canViewInventory === true ||
            permissions.canManageInventory === true))
      ) {
        return;
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

  private response(data: unknown, alreadyApplied = false) {
    return {
      data,
      meta: { alreadyApplied, requestId: `req_${ulid()}` },
    };
  }
}
