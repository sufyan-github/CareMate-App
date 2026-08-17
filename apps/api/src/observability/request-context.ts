import type { NextFunction, Request, Response } from "express";
import { ulid } from "ulid";

const safeRequestId = /^[A-Za-z0-9_-]{8,80}$/u;

export function resolveRequestId(value: unknown): string {
  return typeof value === "string" && safeRequestId.test(value)
    ? value
    : `req_${ulid()}`;
}

export function requestContext(
  request: Request & { careMateRequestId?: string },
  response: Response,
  next: NextFunction,
): void {
  const requestId = resolveRequestId(request.header("x-request-id"));
  request.careMateRequestId = requestId;
  response.setHeader("x-request-id", requestId);
  next();
}
