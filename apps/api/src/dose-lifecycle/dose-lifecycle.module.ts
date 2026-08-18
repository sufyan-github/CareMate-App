import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import { CaregiverAlertsModule } from "../caregiver-alerts/caregiver-alerts.module.js";
import {
  DoseLifecycleCompetitionController,
  DoseLifecycleController,
} from "./dose-lifecycle.controller.js";
import { DoseLifecycleService } from "./dose-lifecycle.service.js";

@Module({
  imports: [AuthModule, CaregiverAlertsModule],
  controllers: [DoseLifecycleController, DoseLifecycleCompetitionController],
  providers: [DoseLifecycleService],
  exports: [DoseLifecycleService],
})
export class DoseLifecycleModule {}
