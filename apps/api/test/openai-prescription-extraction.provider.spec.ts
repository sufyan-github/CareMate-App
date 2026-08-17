import { ConfigService } from "@nestjs/config";
import { afterEach, describe, expect, it, vi } from "vitest";

const parseResponse = vi.hoisted(() => vi.fn());

vi.mock("openai", () => ({
  default: class OpenAI {
    responses = { parse: parseResponse };
  },
}));

import {
  OPENAI_PRESCRIPTION_DEVELOPER_PROMPT,
  OPENAI_PRESCRIPTION_PROMPT_VERSION,
  OpenAiPrescriptionExtractionProvider,
} from "../src/prescription-extraction/openai-prescription-extraction.provider.js";

function config(values: Record<string, string | undefined>): ConfigService {
  return {
    get: vi.fn((key: string) => values[key]),
  } as unknown as ConfigService;
}

describe("OpenAI prescription extraction provider", () => {
  afterEach(() => vi.clearAllMocks());

  it("uses a medicine-name-focused prompt and structured image evidence", async () => {
    parseResponse.mockResolvedValue({
      output_parsed: {
        documentType: "PRESCRIPTION",
        language: "ENGLISH",
        medicines: [
          {
            confidence: 0.86,
            displayName: "Seclo",
            evidenceSource: "IMAGE_ONLY",
            evidenceText: "Seclo 20 mg",
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
        warnings: ["Primary OCR did not read the medicine line."],
      },
    });
    const provider = new OpenAiPrescriptionExtractionProvider(
      config({
        OPENAI_API_KEY: "test-key",
        OPENAI_PRESCRIPTION_MODEL: "gpt-5.6-sol",
        PRESCRIPTION_AI_EXTRACTOR: "openai",
      }),
    );

    const result = await provider.extract({
      imageDataUrl: "data:image/png;base64,iVBORw0KGgo=",
      localOcrText: "Dr Rahman\n20 mg",
    });

    expect(result.medicines[0]).toMatchObject({
      displayName: "Seclo",
      evidenceSource: "IMAGE_ONLY",
      evidenceText: "Seclo 20 mg",
    });
    expect(result.rawText).toBe("Dr Rahman\n20 mg");
    expect(result.providerModel).toBe(
      `gpt-5.6-sol@${OPENAI_PRESCRIPTION_PROMPT_VERSION}`,
    );
    const request = parseResponse.mock.calls[0]?.[0];
    expect(request).toMatchObject({
      model: "gpt-5.6-sol",
      store: false,
    });
    expect(request.input[0].content[0].text).toBe(
      OPENAI_PRESCRIPTION_DEVELOPER_PROMPT,
    );
    expect(OPENAI_PRESCRIPTION_DEVELOPER_PROMPT).toContain(
      "Exclude patient, doctor, clinic",
    );
    expect(OPENAI_PRESCRIPTION_DEVELOPER_PROMPT).toContain(
      "IMAGE_ONLY is allowed",
    );
  });

  it("stays disabled unless both the server key and OpenAI extractor are available", () => {
    expect(
      new OpenAiPrescriptionExtractionProvider(
        config({ PRESCRIPTION_AI_EXTRACTOR: "openai" }),
      ).isEnabled(),
    ).toBe(false);
    expect(
      new OpenAiPrescriptionExtractionProvider(
        config({
          OPENAI_API_KEY: "test-key",
          PRESCRIPTION_AI_EXTRACTOR: "disabled",
        }),
      ).isEnabled(),
    ).toBe(false);
  });
});
