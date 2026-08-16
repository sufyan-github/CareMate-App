import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import { CareAccessController } from "./care-access.controller.js";
import { CareAccessService } from "./care-access.service.js";

@Module({
  imports: [AuthModule],
  controllers: [CareAccessController],
  providers: [CareAccessService],
})
export class CareAccessModule {}
