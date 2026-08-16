import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";

import { AuthModule } from "./auth/auth.module.js";
import { DatabaseModule } from "./database/database.module.js";
import { HealthModule } from "./health/health.module.js";

@Module({
  imports: [
    ConfigModule.forRoot({
      envFilePath: ["../../caremate-secrets.env", "../../.env", ".env"],
      isGlobal: true,
    }),
    AuthModule,
    DatabaseModule,
    HealthModule,
  ],
})
export class AppModule {}
