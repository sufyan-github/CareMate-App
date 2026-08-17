import { ConfigService } from "@nestjs/config";
import { describe, expect, it, vi } from "vitest";

import { DatabaseService } from "../src/database/database.service.js";
import { DevelopmentPrescriptionExtractionProvider } from "../src/prescription-extraction/development-prescription-extraction.provider.js";
import { GoogleDocumentAiPrescriptionProvider } from "../src/prescription-extraction/google-document-ai-prescription.provider.js";
import { OpenAiPrescriptionExtractionProvider } from "../src/prescription-extraction/openai-prescription-extraction.provider.js";
import { PrescriptionExtractionService } from "../src/prescription-extraction/prescription-extraction.service.js";
import type { PrescriptionExtractionResult } from "../src/prescription-extraction/prescription-extraction.types.js";

const primaryResult: PrescriptionExtractionResult = {
  documentType: "PRESCRIPTION",
  language: "ENGLISH",
  medicines: [],
  provider: "primary-ocr",
  providerModel: "primary-v1",
  rawText: "Dr Rahman\n20 mg after meal",
  warnings: [],
};

function createService(aiResult: PrescriptionExtractionResult) {
  const createdAt = new Date("2026-08-17T00:00:00.000Z");
  const database = {
    patientProfile: { findFirst: vi.fn().mockResolvedValue({ id: "profile" }) },
    ocrDraft: {
      create: vi.fn().mockImplementation(({ data }) =>
        Promise.resolve({
          ...data,
          createdAt,
          status: "REVIEW_REQUIRED",
        }),
      ),
    },
  } as unknown as DatabaseService;
  const primary = {
    isEnabled: () => true,
    extract: vi.fn().mockResolvedValue(primaryResult),
  } as unknown as DevelopmentPrescriptionExtractionProvider;
  const google = {
    isEnabled: () => false,
  } as unknown as GoogleDocumentAiPrescriptionProvider;
  const openAi = {
    isEnabled: () => true,
    extract: vi.fn().mockResolvedValue(aiResult),
  } as unknown as OpenAiPrescriptionExtractionProvider;
  const config = {
    get: vi.fn((key: string) =>
      key === "OPENAI_PRESCRIPTION_MODEL" ? "gpt-5.6-sol" : undefined,
    ),
  } as unknown as ConfigService;
  return new PrescriptionExtractionService(
    config,
    database,
    primary,
    google,
    openAi,
  );
}

function aiResult(
  evidenceSource: "OCR_TEXT" | "IMAGE_ONLY" | "OCR_AND_IMAGE",
  evidenceText: string,
): PrescriptionExtractionResult {
  return {
    documentType: "PRESCRIPTION",
    language: "ENGLISH",
    medicines: [
      {
        confidence: 0.84,
        displayName: "Seclo",
        evidenceSource,
        evidenceText,
        form: "CAPSULE",
        instructionsText: "",
        mealRelation: "UNSPECIFIED",
        quantityUnit: null,
        quantityValue: null,
        route: "ORAL",
        strengthUnit: "mg",
        strengthValue: 20,
      },
    ],
    provider: "openai",
    providerModel: "gpt-5.6-sol@prompt-v2",
    rawText: primaryResult.rawText,
    warnings: [],
  };
}

describe("prescription AI evidence reconciliation", () => {
  it("keeps a medicine name read from the image when OCR missed it", async () => {
    const service = createService(aiResult("IMAGE_ONLY", "Seclo 20 mg"));

    const result = await service.extract(
      "user",
      "profile",
      { buffer: Buffer.from("image"), mimetype: "image/png" },
      primaryResult.rawText,
    );

    expect(result.data.medicines).toHaveLength(1);
    expect(result.data.medicines[0]).toMatchObject({
      displayName: "Seclo",
      evidenceSource: "IMAGE_ONLY",
    });
    expect(result.data.warnings).toContain(
      "One or more medicine names were read from the prescription image because primary OCR did not contain matching text. Verify the spelling carefully.",
    );
  });

  it("rejects a candidate that claims OCR evidence absent from OCR text", async () => {
    const service = createService(aiResult("OCR_TEXT", "Seclo 20 mg"));

    const result = await service.extract(
      "user",
      "profile",
      { buffer: Buffer.from("image"), mimetype: "image/png" },
      primaryResult.rawText,
    );

    expect(result.data.medicines).toEqual([]);
    expect(result.data.warnings).toContain(
      "One or more AI candidates were removed because their evidence was absent from the primary OCR text.",
    );
  });

  it("matches OCR evidence across punctuation and whitespace differences", async () => {
    const service = createService(aiResult("OCR_TEXT", "20-mg after meal"));

    const result = await service.extract(
      "user",
      "profile",
      { buffer: Buffer.from("image"), mimetype: "image/png" },
      primaryResult.rawText,
    );

    expect(result.data.medicines).toHaveLength(1);
    expect(result.data.warnings).not.toContain(
      "One or more AI candidates were removed because their evidence was absent from the primary OCR text.",
    );
  });
});
