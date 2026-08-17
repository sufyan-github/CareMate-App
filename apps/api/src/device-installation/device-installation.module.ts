import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import { DeviceInstallationController } from "./device-installation.controller.js";
import { DeviceInstallationService } from "./device-installation.service.js";

@Module({
  imports: [AuthModule],
  controllers: [DeviceInstallationController],
  providers: [DeviceInstallationService],
})
export class DeviceInstallationModule {}
