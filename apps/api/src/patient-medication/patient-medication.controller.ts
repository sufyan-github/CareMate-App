import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import {
  CreateMedicationDto,
  CreatePatientProfileDto,
  UpdateMedicationDto,
  UpdatePatientProfileDto,
} from "./patient-medication.dto.js";
import { PatientMedicationService } from "./patient-medication.service.js";

@Controller("patient-profiles")
@UseGuards(AccessSessionGuard)
export class PatientProfileController {
  constructor(private readonly service: PatientMedicationService) {}

  @Post()
  create(
    @Req() request: AuthenticatedRequest,
    @Body() input: CreatePatientProfileDto,
  ) {
    return this.service.createProfile(request.auth.userId, input);
  }

  @Get()
  list(@Req() request: AuthenticatedRequest) {
    return this.service.listProfiles(request.auth.userId);
  }

  @Get(":profileId")
  get(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
  ) {
    return this.service.getProfile(request.auth.userId, profileId);
  }

  @Patch(":profileId")
  update(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
    @Body() input: UpdatePatientProfileDto,
  ) {
    return this.service.updateProfile(request.auth.userId, profileId, input);
  }

  @Post(":profileId/medications")
  createMedication(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
    @Body() input: CreateMedicationDto,
  ) {
    return this.service.createMedication(request.auth.userId, profileId, input);
  }

  @Get(":profileId/medications")
  listMedications(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
  ) {
    return this.service.listMedications(request.auth.userId, profileId);
  }
}

@Controller("medications")
@UseGuards(AccessSessionGuard)
export class MedicationController {
  constructor(private readonly service: PatientMedicationService) {}

  @Get(":medicationId")
  get(
    @Req() request: AuthenticatedRequest,
    @Param("medicationId") medicationId: string,
  ) {
    return this.service.getMedication(request.auth.userId, medicationId);
  }

  @Patch(":medicationId")
  update(
    @Req() request: AuthenticatedRequest,
    @Param("medicationId") medicationId: string,
    @Body() input: UpdateMedicationDto,
  ) {
    return this.service.updateMedication(
      request.auth.userId,
      medicationId,
      input,
    );
  }
}
