import { Body, Controller, Post, Req, UseGuards } from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import { SyncMutationBatchDto } from "./sync.dto.js";
import { SyncService } from "./sync.service.js";

@Controller("sync")
@UseGuards(AccessSessionGuard)
export class SyncController {
  constructor(private readonly service: SyncService) {}

  @Post("mutations:batch")
  apply(
    @Req() request: AuthenticatedRequest,
    @Body() input: SyncMutationBatchDto,
  ) {
    return this.service.apply(
      request.auth.userId,
      request.auth.sessionId,
      input,
    );
  }
}
