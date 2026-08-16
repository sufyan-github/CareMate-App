import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

import {
  PrescriptionExtractionProvider,
  type PrescriptionExtractionInput,
  type PrescriptionExtractionResult,
} from "./prescription-extraction.types.js";

@Injectable()
export class DevelopmentPrescriptionExtractionProvider extends PrescriptionExtractionProvider {
  constructor(private readonly config: ConfigService) {
    super();
  }

  isEnabled(): boolean {
    return (
      this.config
        .get<string>("PRESCRIPTION_OCR_PROVIDER")
        ?.trim()
        .toLowerCase() === "development" &&
      this.config.get<string>("NODE_ENV") !== "production"
    );
  }

  async extract(
    input: PrescriptionExtractionInput,
  ): Promise<PrescriptionExtractionResult> {
    const rawText = input.localOcrText?.trim() || "Demo prescription image";
    const displayName =
      rawText
        .split(/\r?\n/)
        .map((line) => line.trim())
        .find(Boolean) ?? "Unidentified medicine";
    return {
      documentType: "PRESCRIPTION",
      language: /[\u0980-\u09ff]/u.test(rawText) ? "MIXED" : "ENGLISH",
      medicines: [
        {
          confidence: 0.5,
          displayName,
          evidenceText: rawText,
          form: "OTHER",
          instructionsText: rawText,
          mealRelation: "UNSPECIFIED",
          quantityUnit: null,
          quantityValue: null,
          route: "OTHER",
          strengthUnit: null,
          strengthValue: null,
        },
      ],
      provider: "development",
      providerModel: null,
      rawText,
      warnings: [
        "Development extraction is synthetic and must not be used for clinical decisions.",
      ],
    };
  }
}
