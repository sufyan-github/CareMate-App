import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

export interface OtpDeliveryRequest {
  challengeId: string;
  code: string;
  locale: string;
  phoneNumber: string;
  purpose: string;
}

export interface OtpDeliveryProvider {
  send(request: OtpDeliveryRequest): Promise<string>;
}

export const OTP_DELIVERY_PROVIDER = Symbol("OTP_DELIVERY_PROVIDER");

@Injectable()
export class DevelopmentOtpDeliveryProvider implements OtpDeliveryProvider {
  constructor(private readonly config: ConfigService) {}

  code(): string {
    return this.config.get<string>("LOGIN_OTP_DEVELOPMENT_CODE") ?? "123456";
  }

  async send(request: OtpDeliveryRequest): Promise<string> {
    if (this.config.get<string>("LOGIN_OTP_PROVIDER") !== "development") {
      throw new Error(
        "No approved transactional login OTP provider configured",
      );
    }
    return `development:${request.challengeId}`;
  }
}
