import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";
import type { Request } from "express";

import { RefreshTokenDto, RequestOtpDto, VerifyOtpDto } from "./auth.dto.js";
import { AuthService } from "./auth.service.js";
import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "./access-session.guard.js";

@Controller("auth")
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post("otp/requests")
  requestOtp(@Body() input: RequestOtpDto, @Req() request: Request) {
    return this.auth.requestOtp(
      input,
      request.ip ?? request.socket.remoteAddress ?? "unknown",
    );
  }

  @Post("otp/verifications")
  verifyOtp(@Body() input: VerifyOtpDto) {
    return this.auth.verifyOtp(input);
  }

  @Post("token/refresh")
  refresh(@Body() input: RefreshTokenDto) {
    return this.auth.refresh(input);
  }

  @Post("logout")
  @UseGuards(AccessSessionGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Req() request: AuthenticatedRequest): Promise<void> {
    await this.auth.logout(request.auth.sessionId);
  }

  @Post("logout-all")
  @UseGuards(AccessSessionGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async logoutAll(@Req() request: AuthenticatedRequest): Promise<void> {
    await this.auth.logoutAll(request.auth.userId);
  }
}
