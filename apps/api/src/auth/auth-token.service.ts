import { HttpStatus, Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { jwtVerify, SignJWT } from "jose";

import { AuthError } from "./auth-error.js";

export interface AccessTokenClaims {
  sessionId: string;
  tokenVersion: number;
  userId: string;
}

@Injectable()
export class AuthTokenService {
  private readonly audience = "caremate-mobile";
  private readonly issuer = "caremate-api";
  private readonly secret: Uint8Array;

  constructor(config: ConfigService) {
    const configured = config.get<string>("ACCESS_TOKEN_SECRET");
    if (
      config.get<string>("NODE_ENV") === "production" &&
      (!configured || configured.length < 32)
    ) {
      throw new Error(
        "ACCESS_TOKEN_SECRET must contain at least 32 characters",
      );
    }
    this.secret = new TextEncoder().encode(
      configured ?? "caremate-development-only-access-token-secret",
    );
  }

  async issueAccessToken(claims: AccessTokenClaims): Promise<string> {
    return new SignJWT({ sid: claims.sessionId, ver: claims.tokenVersion })
      .setProtectedHeader({ alg: "HS256", typ: "JWT" })
      .setSubject(claims.userId)
      .setAudience(this.audience)
      .setIssuer(this.issuer)
      .setIssuedAt()
      .setExpirationTime("15m")
      .sign(this.secret);
  }

  async verifyAccessToken(token: string): Promise<AccessTokenClaims> {
    try {
      const { payload } = await jwtVerify(token, this.secret, {
        audience: this.audience,
        issuer: this.issuer,
      });
      if (
        !payload.sub ||
        typeof payload.sid !== "string" ||
        typeof payload.ver !== "number"
      ) {
        throw new Error("Missing claims");
      }
      return {
        sessionId: payload.sid,
        tokenVersion: payload.ver,
        userId: payload.sub,
      };
    } catch {
      throw new AuthError(
        HttpStatus.UNAUTHORIZED,
        "ACCESS_TOKEN_INVALID",
        "Your session is not valid. Sign in again.",
      );
    }
  }
}
