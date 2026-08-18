import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import { DoseCommandDto, SimulateMissDto } from "./dose-lifecycle.dto.js";
import { DoseLifecycleService } from "./dose-lifecycle.service.js";

@Controller("dose-occurrences")
@UseGuards(AccessSessionGuard)
export class DoseLifecycleController {
  constructor(private readonly service: DoseLifecycleService) {}

  @Get(":occurrenceId")
  get(
    @Req() request: AuthenticatedRequest,
    @Param("occurrenceId") occurrenceId: string,
  ) {
    return this.service.get(request.auth.userId, occurrenceId);
  }

  @Post(":occurrenceId/commands")
  command(
    @Req() request: AuthenticatedRequest,
    @Param("occurrenceId") occurrenceId: string,
    @Body() input: DoseCommandDto,
  ) {
    return this.service.command(
      request.auth.userId,
      request.auth.sessionId,
      occurrenceId,
      input,
    );
  }
}

@Controller("patient-profiles")
@UseGuards(AccessSessionGuard)
export class DoseLifecycleCompetitionController {
  constructor(private readonly service: DoseLifecycleService) {}

  @Post(":profileId/dose-occurrences/simulate-miss")
  simulateMiss(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
    @Body() input: SimulateMissDto,
  ) {
    return this.service.simulateMiss(
      request.auth.userId,
      profileId,
      input.minutesLate,
    );
  }
}
