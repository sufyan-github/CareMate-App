import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import {
  DoseOccurrenceController,
  MedicationScheduleController,
  ScheduleLifecycleController,
} from "./medication-schedule.controller.js";
import { MedicationScheduleService } from "./medication-schedule.service.js";
import { ScheduleEngine } from "./schedule-engine.js";

@Module({
  imports: [AuthModule],
  controllers: [
    MedicationScheduleController,
    ScheduleLifecycleController,
    DoseOccurrenceController,
  ],
  providers: [MedicationScheduleService, ScheduleEngine],
})
export class MedicationScheduleModule {}
