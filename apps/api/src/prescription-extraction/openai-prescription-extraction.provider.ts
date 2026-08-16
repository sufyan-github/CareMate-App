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
  displayName: z.string(),
  evidenceText: z.string(),
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
  rawText: z.string(),
  warnings: z.array(z.string()),
});

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
              text: [
                "Extract only text and medication fields visibly present in this prescription image.",
                "The prescription may contain Bangla, English, mixed scripts, printed text, or handwriting.",
                "The primary OCR evidence supplied by CareMate is the source of truth; use the image only to cross-check it.",
                "Never infer a medicine, dose, frequency, duration, diagnosis, or instruction that is not supported by the OCR evidence and visible image.",
                "Use null for missing numeric/unit values, OTHER or UNSPECIFIED for unknown enums, and add a warning for ambiguity.",
                "Copy the exact supporting OCR words into evidenceText for every medicine; return no medicine when there is no supporting evidence.",
                "This output is an unverified OCR draft and must be reviewed by the user.",
              ].join(" "),
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: input.localOcrText
                ? `On-device OCR hint (untrusted and possibly wrong):\n${input.localOcrText}`
                : "Read this prescription image.",
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
      providerModel: this.model,
    };
  }
}
