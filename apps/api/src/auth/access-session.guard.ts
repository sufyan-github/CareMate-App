import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from "@nestjs/common";
import type { Request } from "express";

import { DatabaseService } from "../database/database.service.js";
import { AuthError } from "./auth-error.js";
import {
  AuthTokenService,
  type AccessTokenClaims,
} from "./auth-token.service.js";

export type AuthenticatedRequest = Request & { auth: AccessTokenClaims };

@Injectable()
export class AccessSessionGuard implements CanActivate {
  constructor(
    private readonly database: DatabaseService,
    private readonly tokens: AuthTokenService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authorization = request.header("authorization");
    if (!authorization?.startsWith("Bearer ")) {
      throw this.revoked();
    }

    const claims = await this.tokens.verifyAccessToken(authorization.slice(7));
    const session = await this.database.authSession.findUnique({
      include: { user: true },
      where: { id: claims.sessionId },
    });
    const now = new Date();
    if (
      !session ||
      session.userId !== claims.userId ||
      session.revokedAt ||
      session.expiresAt <= now ||
      session.user.status !== "ACTIVE" ||
      session.user.tokenVersion !== claims.tokenVersion
    ) {
      throw this.revoked();
    }

    request.auth = claims;
    return true;
  }

  private revoked(): AuthError {
    return new AuthError(
      HttpStatus.UNAUTHORIZED,
      "SESSION_REVOKED",
      "Your session has ended. Sign in again.",
    );
  }
}
