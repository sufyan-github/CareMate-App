import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import { DoseLifecycleModule } from "../dose-lifecycle/dose-lifecycle.module.js";
import { SyncController } from "./sync.controller.js";
import { SyncService } from "./sync.service.js";

@Module({
  imports: [AuthModule, DoseLifecycleModule],
  controllers: [SyncController],
  providers: [SyncService],
})
export class SyncModule {}
