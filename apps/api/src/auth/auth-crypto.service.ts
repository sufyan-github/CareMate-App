import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import {
  createCipheriv,
  createDecipheriv,
  createHash,
  createHmac,
  randomBytes,
  timingSafeEqual,
} from "node:crypto";

@Injectable()
export class AuthCryptoService {
  private readonly encryptionKey: Buffer;
  private readonly lookupPepper: string;
  private readonly otpPepper: string;
  private readonly refreshPepper: string;

  constructor(config: ConfigService) {
    this.encryptionKey = createHash("sha256")
      .update(this.secret(config, "PHONE_ENCRYPTION_KEY"))
      .digest();
    this.lookupPepper = this.secret(config, "PHONE_LOOKUP_PEPPER");
    this.refreshPepper = this.secret(config, "REFRESH_TOKEN_PEPPER");
    this.otpPepper =
      config.get<string>("OTP_HASH_PEPPER") ?? this.refreshPepper;
  }

  encryptPhone(phoneNumber: string): string {
    const initializationVector = randomBytes(12);
    const cipher = createCipheriv(
      "aes-256-gcm",
      this.encryptionKey,
      initializationVector,
    );
    const ciphertext = Buffer.concat([
      cipher.update(phoneNumber, "utf8"),
      cipher.final(),
    ]);
    const tag = cipher.getAuthTag();

    return [initializationVector, tag, ciphertext]
      .map((part) => part.toString("base64url"))
      .join(".");
  }

  decryptPhone(encrypted: string): string {
    const [initializationVector, tag, ciphertext] = encrypted
      .split(".")
      .map((part) => Buffer.from(part, "base64url"));
    if (!initializationVector || !tag || !ciphertext) {
      throw new Error("Invalid encrypted phone value");
    }
    const decipher = createDecipheriv(
      "aes-256-gcm",
      this.encryptionKey,
      initializationVector,
    );
    decipher.setAuthTag(tag);
    return Buffer.concat([
      decipher.update(ciphertext),
      decipher.final(),
    ]).toString("utf8");
  }

  phoneLookupHash(phoneNumber: string): string {
    return this.hmac(this.lookupPepper, phoneNumber);
  }

  riskLookupHash(value: string): string {
    return this.hmac(this.lookupPepper, `risk:${value}`);
  }

  otpHash(challengeId: string, code: string, purpose: string): string {
    return this.hmac(this.otpPepper, `${challengeId}:${code}:${purpose}`);
  }

  refreshTokenHash(token: string): string {
    return this.hmac(this.refreshPepper, token);
  }

  hashesMatch(left: string, right: string): boolean {
    const leftBuffer = Buffer.from(left, "hex");
    const rightBuffer = Buffer.from(right, "hex");
    return (
      leftBuffer.length === rightBuffer.length &&
      timingSafeEqual(leftBuffer, rightBuffer)
    );
  }

  private hmac(secret: string, value: string): string {
    return createHmac("sha256", secret).update(value).digest("hex");
  }

  private secret(config: ConfigService, name: string): string {
    const value = config.get<string>(name);
    if (value && value.length >= 32) {
      return value;
    }
    if (config.get<string>("NODE_ENV") === "production") {
      throw new Error(`${name} must contain at least 32 characters`);
    }
    return `caremate-development-only-${name}-secret`;
  }
}
