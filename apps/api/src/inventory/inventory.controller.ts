import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";

import {
  AccessSessionGuard,
  type AuthenticatedRequest,
} from "../auth/access-session.guard.js";
import {
  CreateStockAdjustmentDto,
  UpdateInventoryPositionDto,
} from "./inventory.dto.js";
import { InventoryService } from "./inventory.service.js";

@Controller()
@UseGuards(AccessSessionGuard)
export class InventoryController {
  constructor(private readonly service: InventoryService) {}

  @Get("patient-profiles/:profileId/inventory")
  list(
    @Req() request: AuthenticatedRequest,
    @Param("profileId") profileId: string,
  ) {
    return this.service.list(request.auth.userId, profileId);
  }

  @Post("inventory/:positionId/adjustments")
  createAdjustment(
    @Req() request: AuthenticatedRequest,
    @Param("positionId") positionId: string,
    @Body() input: CreateStockAdjustmentDto,
  ) {
    return this.service.createAdjustment(
      request.auth.userId,
      positionId,
      input,
    );
  }

  @Patch("inventory/:positionId")
  update(
    @Req() request: AuthenticatedRequest,
    @Param("positionId") positionId: string,
    @Body() input: UpdateInventoryPositionDto,
  ) {
    return this.service.update(request.auth.userId, positionId, input);
  }
}
