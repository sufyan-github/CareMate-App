import { v1 as documentai } from "@google-cloud/documentai";
import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

import {
  PrescriptionExtractionProvider,
  type PrescriptionExtractionInput,
  type PrescriptionExtractionResult,
} from "./prescription-extraction.types.js";

@Injectable()
export class GoogleDocumentAiPrescriptionProvider extends PrescriptionExtractionProvider {
  private readonly location: string;
  private readonly processorId: string | undefined;
  private readonly projectId: string | undefined;

  constructor(private readonly config: ConfigService) {
    super();
    this.location =
      this.config.get<string>("GOOGLE_DOCUMENT_AI_LOCATION")?.trim() ||
      "asia-south1";
    this.processorId = this.config
      .get<string>("GOOGLE_DOCUMENT_AI_PROCESSOR_ID")
      ?.trim();
    this.projectId = this.config
      .get<string>("GOOGLE_DOCUMENT_AI_PROJECT_ID")
      ?.trim();
  }

  isEnabled(): boolean {
    const provider = this.config
      .get<string>("PRESCRIPTION_OCR_PROVIDER")
      ?.trim()
      .toLowerCase();
    return (
      Boolean(this.processorId && this.projectId) &&
      (provider === undefined || provider === "google-document-ai")
    );
  }

  async extract(
    input: PrescriptionExtractionInput,
  ): Promise<PrescriptionExtractionResult> {
    if (!this.projectId || !this.processorId) {
      throw new Error("Google Document AI prescription OCR is not configured.");
    }
    const match = /^data:(image\/(?:jpeg|png|webp));base64,(.+)$/u.exec(
      input.imageDataUrl,
    );
    if (!match) throw new Error("Unsupported prescription image data.");

    const client = new documentai.DocumentProcessorServiceClient({
      apiEndpoint: `${this.location}-documentai.googleapis.com`,
    });
    const name = client.processorPath(
      this.projectId,
      this.location,
      this.processorId,
    );
    const [response] = await client.processDocument(
      {
        name,
        rawDocument: { content: match[2]!, mimeType: match[1]! },
      },
      {},
    );
    const rawText = response.document?.text?.trim() ?? "";
    return {
      documentType: rawText ? "UNCERTAIN" : "OTHER",
      language: this.language(rawText),
      medicines: [],
      provider: "google-document-ai",
      providerModel: this.processorId,
      rawText,
      warnings: rawText
        ? ["Cloud OCR text requires structured extraction and user review."]
        : ["Google Document AI found no readable prescription text."],
    };
  }

  private language(text: string): PrescriptionExtractionResult["language"] {
    const hasBangla = /[\u0980-\u09ff]/u.test(text);
    const hasLatin = /[a-z]/iu.test(text);
    if (hasBangla && hasLatin) return "MIXED";
    if (hasBangla) return "BANGLA";
    if (hasLatin) return "ENGLISH";
    return "UNKNOWN";
  }
}
