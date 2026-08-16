import {
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Req,
  UseGuards,
} from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "./access-session.guard.js";
import { AuthService } from "./auth.service.js";

@Controller("me/sessions")
@UseGuards(AccessSessionGuard)
export class SessionController {
  constructor(private readonly auth: AuthService) {}

  @Get()
  list(@Req() request: AuthenticatedRequest) {
    return this.auth.listSessions(request.auth.userId, request.auth.sessionId);
  }

  @Delete(":sessionId")
  @HttpCode(HttpStatus.NO_CONTENT)
  async revoke(
    @Req() request: AuthenticatedRequest,
    @Param("sessionId") sessionId: string,
  ): Promise<void> {
    await this.auth.revokeSession(request.auth.userId, sessionId);
  }
}
