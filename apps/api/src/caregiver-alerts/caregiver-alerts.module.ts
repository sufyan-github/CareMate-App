import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import { CaregiverAlertsController } from "./caregiver-alerts.controller.js";
import { CaregiverAlertsService } from "./caregiver-alerts.service.js";

@Module({
  imports: [AuthModule],
  controllers: [CaregiverAlertsController],
  providers: [CaregiverAlertsService],
  exports: [CaregiverAlertsService],
})
export class CaregiverAlertsModule {}
