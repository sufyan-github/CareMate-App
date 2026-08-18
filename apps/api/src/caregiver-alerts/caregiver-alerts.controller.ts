import {
  Controller,
  Get,
  Param,
  Patch,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import { CaregiverAlertsService } from "./caregiver-alerts.service.js";

@Controller("caregiver-alerts")
@UseGuards(AccessSessionGuard)
export class CaregiverAlertsController {
  constructor(private readonly service: CaregiverAlertsService) {}

  @Get()
  list(
    @Req() request: AuthenticatedRequest,
    @Query("profileId") profileId: string,
  ) {
    return this.service.list(request.auth.userId, profileId);
  }

  @Patch(":alertId/acknowledge")
  acknowledge(
    @Req() request: AuthenticatedRequest,
    @Param("alertId") alertId: string,
  ) {
    return this.service.acknowledge(request.auth.userId, alertId);
  }

  @Get(":alertId/audit")
  audit(
    @Req() request: AuthenticatedRequest,
    @Param("alertId") alertId: string,
  ) {
    return this.service.audit(request.auth.userId, alertId);
  }
}
