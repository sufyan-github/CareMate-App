import { Module } from "@nestjs/common";

import { AccessSessionGuard } from "./access-session.guard.js";
import { AuthController } from "./auth.controller.js";
import { AuthCryptoService } from "./auth-crypto.service.js";
import { AuthService } from "./auth.service.js";
import { AuthTokenService } from "./auth-token.service.js";
import {
  DevelopmentOtpDeliveryProvider,
  OTP_DELIVERY_PROVIDER,
} from "./otp-delivery.provider.js";
import { SessionController } from "./session.controller.js";

@Module({
  controllers: [AuthController, SessionController],
  providers: [
    AccessSessionGuard,
    AuthCryptoService,
    AuthService,
    AuthTokenService,
    DevelopmentOtpDeliveryProvider,
    {
      provide: OTP_DELIVERY_PROVIDER,
      useExisting: DevelopmentOtpDeliveryProvider,
    },
  ],
  exports: [AccessSessionGuard, AuthCryptoService, AuthTokenService],
})
export class AuthModule {}
