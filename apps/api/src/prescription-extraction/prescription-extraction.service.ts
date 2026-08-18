import { HttpStatus, Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { ulid } from "ulid";

import { AuthError } from "../auth/auth-error.js";
import { DatabaseService } from "../database/database.service.js";
import { DevelopmentPrescriptionExtractionProvider } from "./development-prescription-extraction.provider.js";
import { GoogleDocumentAiPrescriptionProvider } from "./google-document-ai-prescription.provider.js";
import { OpenAiPrescriptionExtractionProvider } from "./openai-prescription-extraction.provider.js";
import type { PrescriptionExtractionResult } from "./prescription-extraction.types.js";

@Injectable()
export class PrescriptionExtractionService {
  constructor(
    private readonly config: ConfigService,
    private readonly database: DatabaseService,
    private readonly development: DevelopmentPrescriptionExtractionProvider,
    private readonly googleDocumentAi: GoogleDocumentAiPrescriptionProvider,
    private readonly openAi: OpenAiPrescriptionExtractionProvider,
  ) {}

  async extract(
    userId: string,
    patientProfileId: string,
    file: { buffer: Buffer; mimetype: string },
    localOcrText?: string,
  ) {
    const profile = await this.database.patientProfile.findFirst({
      where: { id: patientProfileId, ownerUserId: userId },
    });
    if (!profile) {
      throw new AuthError(
        HttpStatus.NOT_FOUND,
        "RESOURCE_NOT_FOUND",
        "The requested patient profile was not found.",
      );
    }

    const primaryProvider = this.development.isEnabled()
      ? this.development
      : this.googleDocumentAi.isEnabled()
        ? this.googleDocumentAi
        : null;
    if (!primaryProvider && !localOcrText?.trim()) {
      throw new AuthError(
        HttpStatus.SERVICE_UNAVAILABLE,
        "OCR_PROVIDER_UNAVAILABLE",
        "Bangla prescription OCR is not configured. Continue with on-device English OCR or manual entry.",
      );
    }

    let primary: PrescriptionExtractionResult;
    try {
      primary = primaryProvider
        ? await primaryProvider.extract({
            imageDataUrl: `data:${file.mimetype};base64,${file.buffer.toString("base64")}`,
            ...(localOcrText ? { localOcrText } : {}),
          })
        : this.localEvidence(localOcrText!);
    } catch {
      throw new AuthError(
        HttpStatus.BAD_GATEWAY,
        "OCR_EXTRACTION_FAILED",
        "The primary OCR provider could not read this prescription. Continue with on-device OCR or manual entry.",
      );
    }

    let extracted = primary;
    if (primary.rawText && this.openAi.isEnabled()) {
      try {
        const structured = await this.openAi.extract({
          imageDataUrl: `data:${file.mimetype};base64,${file.buffer.toString("base64")}`,
          localOcrText: primary.rawText,
        });
        const normalizedEvidence = this.normalizeEvidence(primary.rawText);
        let imageEvidenceCount = 0;
        let rejectedCandidateCount = 0;
        const medicines = structured.medicines.flatMap((medicine) => {
          const evidence = this.normalizeEvidence(medicine.evidenceText);
          if (!evidence || !medicine.displayName.trim()) {
            rejectedCandidateCount += 1;
            return [];
          }
          const matchesOcr = normalizedEvidence.includes(evidence);
          if (medicine.evidenceSource === "OCR_TEXT" && !matchesOcr) {
            rejectedCandidateCount += 1;
            return [];
          }
          if (medicine.evidenceSource === "IMAGE_ONLY" || !matchesOcr) {
            imageEvidenceCount += 1;
            return [{ ...medicine, evidenceSource: "IMAGE_ONLY" as const }];
          }
          return [medicine];
        });
        const rejectedCandidateWarning =
          rejectedCandidateCount === 0
            ? []
            : [
                "One or more AI candidates were removed because their evidence was absent from the primary OCR text.",
              ];
        const imageEvidenceWarning =
          imageEvidenceCount === 0
            ? []
            : [
                "One or more medicine names were read from the prescription image because primary OCR did not contain matching text. Verify the spelling carefully.",
              ];
        extracted = {
          ...structured,
          medicines,
          provider: `${primary.provider}+openai`,
          providerModel: [primary.providerModel, structured.providerModel]
            .filter(Boolean)
            .join(" + "),
          rawText: primary.rawText,
          warnings: [
            ...primary.warnings,
            ...structured.warnings,
            ...rejectedCandidateWarning,
            ...imageEvidenceWarning,
          ],
        };
      } catch {
        extracted = {
          ...primary,
          warnings: [
            ...primary.warnings,
            "AI structuring was unavailable. Review the primary OCR text manually.",
          ],
        };
      }
    }

    const draft = await this.database.ocrDraft.create({
      data: {
        documentType: extracted.documentType,
        id: ulid(),
        language: extracted.language,
        medicinesJson: JSON.stringify(extracted.medicines),
        patientProfileId,
        provider: extracted.provider,
        providerModel: extracted.providerModel,
        rawText: extracted.rawText,
        warningsJson: JSON.stringify(extracted.warnings),
      },
    });
    return {
      data: {
        createdAt: draft.createdAt.toISOString(),
        documentType: draft.documentType,
        id: draft.id,
        language: draft.language,
        medicines: extracted.medicines,
        provider: draft.provider,
        providerModel: draft.providerModel,
        rawText: draft.rawText,
        status: draft.status,
        warnings: extracted.warnings,
      },
      meta: {
        modelConfigured:
          this.config.get<string>("OPENAI_PRESCRIPTION_MODEL") ?? null,
        requestId: `req_${ulid()}`,
      },
    };
  }

  private localEvidence(rawText: string): PrescriptionExtractionResult {
    const hasBangla = /[\u0980-\u09ff]/u.test(rawText);
    const hasLatin = /[a-z]/iu.test(rawText);
    return {
      documentType: "UNCERTAIN",
      language: hasBangla
        ? hasLatin
          ? "MIXED"
          : "BANGLA"
        : hasLatin
          ? "ENGLISH"
          : "UNKNOWN",
      medicines: [],
      provider: "on-device-mlkit-preview",
      providerModel: "latin",
      rawText,
      warnings: [
        "On-device preview supports English printed text only; review every field manually.",
      ],
    };
  }

  private normalizeEvidence(value: string): string {
    return value
      .normalize("NFKC")
      .toLocaleLowerCase("en-US")
      .replace(/[^\p{L}\p{N}]+/gu, " ")
      .trim();
  }
}
