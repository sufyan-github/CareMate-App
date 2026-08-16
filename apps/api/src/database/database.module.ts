import { Global, Module } from "@nestjs/common";

import { DatabaseMigrationService } from "./database-migration.service.js";
import { DatabaseService } from "./database.service.js";

@Global()
@Module({
  providers: [DatabaseService, DatabaseMigrationService],
  exports: [DatabaseService],
})
export class DatabaseModule {}
