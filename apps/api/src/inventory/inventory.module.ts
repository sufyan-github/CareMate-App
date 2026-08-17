import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import { InventoryController } from "./inventory.controller.js";
import { InventoryService } from "./inventory.service.js";

@Module({
  controllers: [InventoryController],
  imports: [AuthModule],
  providers: [InventoryService],
})
export class InventoryModule {}
