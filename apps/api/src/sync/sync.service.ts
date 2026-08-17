import { HttpException, Injectable } from "@nestjs/common";
import { ulid } from "ulid";

import { DoseLifecycleService } from "../dose-lifecycle/dose-lifecycle.service.js";
import { DatabaseService } from "../database/database.service.js";
import type { SyncMutationBatchDto, SyncMutationDto } from "./sync.dto.js";

@Injectable()
export class SyncService {
  constructor(
    private readonly database: DatabaseService,
    private readonly doseLifecycle: DoseLifecycleService,
  ) {}

  async apply(userId: string, sessionId: string, input: SyncMutationBatchDto) {
    const results = [];
    for (const mutation of input.mutations) {
      results.push(await this.applyOne(userId, sessionId, mutation));
    }
    return {
      data: { results },
      meta: {
        requestId: `req_${ulid()}`,
        serverTime: new Date().toISOString(),
      },
    };
  }

  private async applyOne(
    userId: string,
    sessionId: string,
    mutation: SyncMutationDto,
  ) {
    try {
      const session = await this.database.authSession.findFirst({
        select: { installationId: true },
        where: { id: sessionId, revokedAt: null, userId },
      });
      if (session?.installationId !== mutation.installationId) {
        return {
          error: {
            code: "INSTALLATION_SESSION_MISMATCH",
            message:
              "This session cannot submit another installation's change.",
          },
          mutationId: mutation.mutationId,
          status: "REJECTED",
        };
      }
      const response = await this.doseLifecycle.command(
        userId,
        sessionId,
        mutation.entityId,
        {
          clientAt: mutation.clientAt,
          clientMutationId: mutation.mutationId,
          command: mutation.command,
          expectedVersion: mutation.baseVersion,
          ...(mutation.payload ? { payload: mutation.payload } : {}),
        },
      );
      return {
        authoritative: response.data,
        mutationId: mutation.mutationId,
        status: response.meta.alreadyApplied ? "ALREADY_APPLIED" : "ACCEPTED",
      };
    } catch (error) {
      if (!(error instanceof HttpException)) {
        const retryable = this.isTemporaryFailure(error);
        return {
          error: {
            code: retryable
              ? "SYNC_TEMPORARY_FAILURE"
              : "SYNC_INTERNAL_FAILURE",
            message: retryable
              ? "CareMate could not process this change yet."
              : "CareMate could not safely apply this change.",
          },
          mutationId: mutation.mutationId,
          status: retryable ? "RETRY_LATER" : "REJECTED",
        };
      }
      const detail = this.errorDetail(error);
      const conflict = [
        "CLIENT_MUTATION_ID_REUSED",
        "DOSE_TRANSITION_INVALID",
        "DOSE_VERSION_CONFLICT",
      ].includes(detail.code);
      let authoritative: unknown;
      if (conflict) {
        try {
          const current = await this.doseLifecycle.get(
            userId,
            mutation.entityId,
          );
          authoritative = current.data;
        } catch {
          // A conflict response must remain batch-isolated even if the entity
          // was concurrently removed or access was revoked.
        }
      }
      return {
        ...(authoritative === undefined ? {} : { authoritative }),
        error: detail,
        mutationId: mutation.mutationId,
        status: conflict ? "CONFLICT" : "REJECTED",
      };
    }
  }

  private isTemporaryFailure(error: unknown): boolean {
    const message = error instanceof Error ? error.message : String(error);
    return /busy|connection|locked|network|socket|temporar|timeout|unavailable/i.test(
      message,
    );
  }

  private errorDetail(error: HttpException): { code: string; message: string } {
    const response = error.getResponse();
    if (
      typeof response === "object" &&
      response !== null &&
      "error" in response
    ) {
      const detail = (response as { error?: unknown }).error;
      if (
        typeof detail === "object" &&
        detail !== null &&
        "code" in detail &&
        "message" in detail
      ) {
        return {
          code: String((detail as { code: unknown }).code),
          message: String((detail as { message: unknown }).message),
        };
      }
    }
    return { code: "SYNC_MUTATION_REJECTED", message: error.message };
  }
}
