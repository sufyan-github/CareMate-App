import {
  Body,
  Controller,
  Delete,
  HttpCode,
  HttpStatus,
  Param,
  Put,
  Req,
  UseGuards,
} from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import { RegisterDeviceInstallationDto } from "./device-installation.dto.js";
import { DeviceInstallationService } from "./device-installation.service.js";

@Controller("devices")
@UseGuards(AccessSessionGuard)
export class DeviceInstallationController {
  constructor(private readonly service: DeviceInstallationService) {}

  @Put(":installationId")
  register(
    @Req() request: AuthenticatedRequest,
    @Param("installationId") installationId: string,
    @Body() input: RegisterDeviceInstallationDto,
  ) {
    return this.service.register(
      request.auth.userId,
      request.auth.sessionId,
      installationId,
      input,
    );
  }

  @Delete(":installationId/push-token")
  @HttpCode(HttpStatus.NO_CONTENT)
  async detachPushToken(
    @Req() request: AuthenticatedRequest,
    @Param("installationId") installationId: string,
  ): Promise<void> {
    await this.service.detachPushToken(
      request.auth.userId,
      request.auth.sessionId,
      installationId,
    );
  }
}
