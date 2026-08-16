import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import {
  MedicationController,
  PatientProfileController,
} from "./patient-medication.controller.js";
import { PatientMedicationService } from "./patient-medication.service.js";

@Module({
  imports: [AuthModule],
  controllers: [PatientProfileController, MedicationController],
  providers: [PatientMedicationService],
})
export class PatientMedicationModule {}
