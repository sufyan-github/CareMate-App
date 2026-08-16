import { Module } from "@nestjs/common";

import { AuthModule } from "../auth/auth.module.js";
import { DevelopmentPrescriptionExtractionProvider } from "./development-prescription-extraction.provider.js";
import { GoogleDocumentAiPrescriptionProvider } from "./google-document-ai-prescription.provider.js";
import { OpenAiPrescriptionExtractionProvider } from "./openai-prescription-extraction.provider.js";
import { PrescriptionExtractionController } from "./prescription-extraction.controller.js";
import { PrescriptionExtractionService } from "./prescription-extraction.service.js";

@Module({
  imports: [AuthModule],
  controllers: [PrescriptionExtractionController],
  providers: [
    DevelopmentPrescriptionExtractionProvider,
    GoogleDocumentAiPrescriptionProvider,
    OpenAiPrescriptionExtractionProvider,
    PrescriptionExtractionService,
  ],
})
export class PrescriptionExtractionModule {}
