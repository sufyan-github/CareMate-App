import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";

import { AuthModule } from "./auth/auth.module.js";
import { DatabaseModule } from "./database/database.module.js";
import { HealthModule } from "./health/health.module.js";
import { PatientMedicationModule } from "./patient-medication/patient-medication.module.js";
import { PrescriptionExtractionModule } from "./prescription-extraction/prescription-extraction.module.js";

@Module({
  imports: [
    ConfigModule.forRoot({
      envFilePath: ["../../caremate-secrets.env", "../../.env", ".env"],
      isGlobal: true,
    }),
    AuthModule,
    DatabaseModule,
    HealthModule,
    PatientMedicationModule,
    PrescriptionExtractionModule,
  ],
})
export class AppModule {}
