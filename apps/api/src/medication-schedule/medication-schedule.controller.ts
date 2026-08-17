import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import {
  CreateMedicationScheduleDto,
  DoseOccurrenceWindowDto,
  ScheduleCommandDto,
  UpdateMedicationScheduleDto,
} from "./medication-schedule.dto.js";
import { MedicationScheduleService } from "./medication-schedule.service.js";

@Controller("medications")
@UseGuards(AccessSessionGuard)
export class MedicationScheduleController {
  constructor(private readonly service: MedicationScheduleService) {}

  @Post(":medicationId/schedules")
  create(
    @Req() request: AuthenticatedRequest,
    @Param("medicationId") medicationId: string,
    @Body() input: CreateMedicationScheduleDto,
  ) {
    return this.service.create(request.auth.userId, medicationId, input);
  }
}

@Controller("schedules")
@UseGuards(AccessSessionGuard)
export class ScheduleLifecycleController {
  constructor(private readonly service: MedicationScheduleService) {}

  @Patch(":scheduleId")
  update(
    @Req() request: AuthenticatedRequest,
    @Param("scheduleId") scheduleId: string,
    @Body() input: UpdateMedicationScheduleDto,
  ) {
    return this.service.update(request.auth.userId, scheduleId, input);
  }

  @Post(":scheduleId/pause")
  pause(
    @Req() request: AuthenticatedRequest,
    @Param("scheduleId") scheduleId: string,
    @Body() input: ScheduleCommandDto,
  ) {
    return this.service.pause(request.auth.userId, scheduleId, input);
  }

  @Post(":scheduleId/resume")
  resume(
    @Req() request: AuthenticatedRequest,
    @Param("scheduleId") scheduleId: string,
    @Body() input: ScheduleCommandDto,
  ) {
    return this.service.resume(request.auth.userId, scheduleId, input);
  }

  @Post(":scheduleId/end")
  end(
    @Req() request: AuthenticatedRequest,
    @Param("scheduleId") scheduleId: string,
    @Body() input: ScheduleCommandDto,
  ) {
    return this.service.end(request.auth.userId, scheduleId, input);
  }
}

@Controller("patient-profiles")
@UseGuards(AccessSessionGuard)
export class DoseOccurrenceController {
  constructor(private readonly service: MedicationScheduleService) {}

  @Get(":profileId/dose-occurrences")
  list(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
    @Query() window: DoseOccurrenceWindowDto,
  ) {
    return this.service.listOccurrences(request.auth.userId, profileId, window);
  }
}
