import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import { DoseLifecycleModule } from "../dose-lifecycle/dose-lifecycle.module.js";
import { ReportingController } from "./reporting.controller.js";
import { ReportingService } from "./reporting.service.js";

@Module({
  controllers: [ReportingController],
  imports: [AuthModule, DoseLifecycleModule],
  providers: [ReportingService],
})
export class ReportingModule {}
