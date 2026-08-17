export type PrescriptionMedicineDraft = {
  confidence: number;
  displayName: string;
  evidenceSource: "OCR_TEXT" | "IMAGE_ONLY" | "OCR_AND_IMAGE";
  evidenceText: string;
  form: "TABLET" | "CAPSULE" | "SYRUP" | "INJECTION" | "DROPS" | "OTHER";
  instructionsText: string;
  mealRelation: "BEFORE" | "WITH" | "AFTER" | "UNSPECIFIED";
  quantityUnit: string | null;
  quantityValue: number | null;
  route: "ORAL" | "TOPICAL" | "INHALED" | "INJECTED" | "OTHER";
  strengthUnit: string | null;
  strengthValue: number | null;
};

export type PrescriptionExtractionResult = {
  documentType: "PRESCRIPTION" | "OTHER" | "UNCERTAIN";
  language: "BANGLA" | "ENGLISH" | "MIXED" | "UNKNOWN";
  medicines: PrescriptionMedicineDraft[];
  provider: string;
  providerModel: string | null;
  rawText: string;
  warnings: string[];
};

export type PrescriptionExtractionInput = {
  imageDataUrl: string;
  localOcrText?: string;
};

export abstract class PrescriptionExtractionProvider {
  abstract isEnabled(): boolean;
  abstract extract(
    input: PrescriptionExtractionInput,
  ): Promise<PrescriptionExtractionResult>;
}
