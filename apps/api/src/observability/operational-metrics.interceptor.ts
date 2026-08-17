import {
  CallHandler,
  ExecutionContext,
  HttpException,
  Injectable,
  Logger,
  NestInterceptor,
} from "@nestjs/common";
import type { Request, Response } from "express";
import type { Observable } from "rxjs";
import { tap } from "rxjs/operators";

interface OperationalEvent {
  controller: string;
  durationMs: number;
  event: "http_request_completed";
  handler: string;
  method: string;
  outcome: "success" | "failure";
  requestId: string;
  statusCode: number;
}

export function buildOperationalEvent(input: {
  controller: string;
  durationMs: number;
  handler: string;
  method: string;
  requestId: string;
  statusCode: number;
}): OperationalEvent {
  return {
    ...input,
    durationMs: Math.max(0, Math.round(input.durationMs)),
    event: "http_request_completed",
    outcome: input.statusCode >= 400 ? "failure" : "success",
  };
}

@Injectable()
export class OperationalMetricsInterceptor implements NestInterceptor {
  private readonly logger = new Logger("OperationalMetrics");

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context
      .switchToHttp()
      .getRequest<Request & { careMateRequestId?: string }>();
    const response = context.switchToHttp().getResponse<Response>();
    const startedAt = performance.now();
    const base = {
      controller: context.getClass().name,
      handler: context.getHandler().name,
      method: request.method,
      requestId: request.careMateRequestId ?? "request-id-unavailable",
    };
    const log = (statusCode: number): void => {
      this.logger.log(
        JSON.stringify(
          buildOperationalEvent({
            ...base,
            durationMs: performance.now() - startedAt,
            statusCode,
          }),
        ),
      );
    };

    return next.handle().pipe(
      tap({
        error: (error: unknown) =>
          log(error instanceof HttpException ? error.getStatus() : 500),
        next: () => log(response.statusCode),
      }),
    );
  }
}
