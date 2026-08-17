import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import OpenAI from "openai";
import { zodTextFormat } from "openai/helpers/zod";
import { z } from "zod";

import {
  PrescriptionExtractionProvider,
  type PrescriptionExtractionInput,
  type PrescriptionExtractionResult,
} from "./prescription-extraction.types.js";

const medicineSchema = z.object({
  confidence: z.number().min(0).max(1),
  displayName: z.string().min(1).max(160),
  evidenceSource: z.enum(["OCR_TEXT", "IMAGE_ONLY", "OCR_AND_IMAGE"]),
  evidenceText: z.string().min(1).max(500),
  form: z.enum(["TABLET", "CAPSULE", "SYRUP", "INJECTION", "DROPS", "OTHER"]),
  instructionsText: z.string(),
  mealRelation: z.enum(["BEFORE", "WITH", "AFTER", "UNSPECIFIED"]),
  quantityUnit: z.string().nullable(),
  quantityValue: z.number().positive().nullable(),
  route: z.enum(["ORAL", "TOPICAL", "INHALED", "INJECTED", "OTHER"]),
  strengthUnit: z.string().nullable(),
  strengthValue: z.number().positive().nullable(),
});

const extractionSchema = z.object({
  documentType: z.enum(["PRESCRIPTION", "OTHER", "UNCERTAIN"]),
  language: z.enum(["BANGLA", "ENGLISH", "MIXED", "UNKNOWN"]),
  medicines: z.array(medicineSchema),
  warnings: z.array(z.string()),
});

export const OPENAI_PRESCRIPTION_PROMPT_VERSION =
  "caremate-prescription-extraction-v2";

export const OPENAI_PRESCRIPTION_DEVELOPER_PROMPT = [
  "You transcribe medicine entries from a prescription into an unverified CareMate review draft.",
  "Prioritize exact medicine-name detection. Inspect the prescription image directly; treat the supplied OCR text as a noisy hint that may omit, split, or misspell the medicine name.",
  "Prescriptions may use Bangla, English, mixed scripts, handwriting, brand names, generic names, abbreviations, numbered rows, and Rx symbols.",
  "For displayName, copy only the medicine name as visibly written. Exclude patient, doctor, clinic, diagnosis, test, date, registration, phone, address, and instruction text. Put strength, form, route, quantity, meal relation, and directions only in their matching fields.",
  "Do not translate, silently correct spelling, expand abbreviations, normalize a brand to a generic, or infer a medicine from usual treatment. Preserve the visible script and spelling.",
  "For every medicine, copy the smallest exact visible phrase that supports the name into evidenceText and identify whether it came from OCR_TEXT, IMAGE_ONLY, or OCR_AND_IMAGE.",
  "IMAGE_ONLY is allowed when the image is readable but the OCR hint is missing or corrupted. If neither source visibly supports a medicine name, return no medicine instead of guessing.",
  "Order medicines as they appear in the document. Confidence describes transcription readability, not clinical correctness. Add a warning for low confidence, conflicting OCR/image text, illegible characters, or multiple plausible readings.",
  "Never infer dose, frequency, duration, diagnosis, or instructions. Use null for missing numeric or unit values and OTHER or UNSPECIFIED for unknown enums.",
  "The result is not medical advice and must remain editable until the user checks it against the prescription.",
].join(" ");

@Injectable()
export class OpenAiPrescriptionExtractionProvider extends PrescriptionExtractionProvider {
  private readonly apiKey: string | undefined;
  private readonly model: string;

  constructor(private readonly config: ConfigService) {
    super();
    this.apiKey = this.config.get<string>("OPENAI_API_KEY")?.trim();
    this.model =
      this.config.get<string>("OPENAI_PRESCRIPTION_MODEL")?.trim() ||
      "gpt-5.6-sol";
  }

  isEnabled(): boolean {
    const extractor = this.config
      .get<string>("PRESCRIPTION_AI_EXTRACTOR")
      ?.trim()
      .toLowerCase();
    return (
      Boolean(this.apiKey) &&
      (extractor === undefined || extractor === "openai")
    );
  }

  async extract(
    input: PrescriptionExtractionInput,
  ): Promise<PrescriptionExtractionResult> {
    if (!this.apiKey)
      throw new Error("OpenAI prescription OCR is not configured.");
    const client = new OpenAI({ apiKey: this.apiKey });
    const response = await client.responses.parse({
      input: [
        {
          role: "developer",
          content: [
            {
              type: "input_text",
              text: OPENAI_PRESCRIPTION_DEVELOPER_PROMPT,
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: input.localOcrText
                ? `Noisy OCR hint; preserve it as evidence only when it matches the image:\n${input.localOcrText}`
                : "No OCR hint is available. Transcribe only medicine names that are visibly readable in the image.",
            },
            {
              detail: "original",
              image_url: input.imageDataUrl,
              type: "input_image",
            },
          ],
        },
      ],
      model: this.model,
      store: false,
      text: {
        format: zodTextFormat(extractionSchema, "caremate_prescription_draft"),
      },
    });
    const parsed = response.output_parsed;
    if (!parsed)
      throw new Error("The OCR provider returned no structured draft.");
    return {
      ...parsed,
      provider: "openai",
      providerModel: `${this.model}@${OPENAI_PRESCRIPTION_PROMPT_VERSION}`,
      rawText: input.localOcrText?.trim() ?? "",
    };
  }
}
