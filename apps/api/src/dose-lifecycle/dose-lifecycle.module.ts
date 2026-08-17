import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import { DoseLifecycleController } from "./dose-lifecycle.controller.js";
import { DoseLifecycleService } from "./dose-lifecycle.service.js";

@Module({
  imports: [AuthModule],
  controllers: [DoseLifecycleController],
  providers: [DoseLifecycleService],
  exports: [DoseLifecycleService],
})
export class DoseLifecycleModule {}
