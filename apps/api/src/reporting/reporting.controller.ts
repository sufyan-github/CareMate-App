import { Controller, Get, Param, Query, Req, UseGuards } from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import { IndicatorWindowDto } from "./reporting.dto.js";
import { ReportingService } from "./reporting.service.js";

@Controller("patient-profiles")
@UseGuards(AccessSessionGuard)
export class ReportingController {
  constructor(private readonly service: ReportingService) {}

  @Get(":profileId/indicators")
  indicator(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
    @Query() window: IndicatorWindowDto,
  ) {
    return this.service.indicator(request.auth.userId, profileId, window);
  }
}
