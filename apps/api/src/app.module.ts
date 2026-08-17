import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";

import { AuthModule } from "./auth/auth.module.js";
import { CareAccessModule } from "./care-access/care-access.module.js";
import { DatabaseModule } from "./database/database.module.js";
import { DeviceInstallationModule } from "./device-installation/device-installation.module.js";
import { DoseLifecycleModule } from "./dose-lifecycle/dose-lifecycle.module.js";
import { HealthModule } from "./health/health.module.js";
import { InventoryModule } from "./inventory/inventory.module.js";
import { MedicationScheduleModule } from "./medication-schedule/medication-schedule.module.js";
import { PatientMedicationModule } from "./patient-medication/patient-medication.module.js";
import { PrescriptionExtractionModule } from "./prescription-extraction/prescription-extraction.module.js";
import { ReportingModule } from "./reporting/reporting.module.js";
import { SyncModule } from "./sync/sync.module.js";

@Module({
  imports: [
    ConfigModule.forRoot({
      envFilePath: ["../../caremate-secrets.env", "../../.env", ".env"],
      isGlobal: true,
    }),
    AuthModule,
    CareAccessModule,
    DatabaseModule,
    DeviceInstallationModule,
    DoseLifecycleModule,
    HealthModule,
    InventoryModule,
    MedicationScheduleModule,
    PatientMedicationModule,
    PrescriptionExtractionModule,
    ReportingModule,
    SyncModule,
  ],
})
export class AppModule {}
