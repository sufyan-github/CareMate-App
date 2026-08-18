import { Controller, Get, ServiceUnavailableException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

import { featureEnabled } from "../config/feature-flags.js";
import { DatabaseService } from "../database/database.service.js";

interface HealthResponse {
  data: {
    database: "reachable";
    service: "caremate-api";
    status: "ok";
  };
  meta: {
    serverTime: string;
  };
}

@Controller("health")
export class HealthController {
  constructor(
    private readonly config: ConfigService,
    private readonly database: DatabaseService,
  ) {}

  @Get()
  async getHealth(): Promise<HealthResponse> {
    if (!(await this.database.isReachable())) {
      throw new ServiceUnavailableException("Database is unavailable.");
    }

    return {
      data: {
        database: "reachable",
        service: "caremate-api",
        status: "ok",
      },
      meta: {
        serverTime: new Date().toISOString(),
      },
    };
  }

  @Get("readiness")
  async getReadiness() {
    if (!(await this.database.isReachable())) {
      throw new ServiceUnavailableException("Database is unavailable.");
    }
    const cloudOcrEnabled = featureEnabled(
      this.config,
      "PRESCRIPTION_CLOUD_OCR_ENABLED",
    );
    const aiEnabled = featureEnabled(this.config, "PRESCRIPTION_AI_ENABLED");
    const ocrProvider = this.config
      .get<string>("PRESCRIPTION_OCR_PROVIDER")
      ?.trim()
      .toLowerCase();
    const googleConfigured = Boolean(
      this.config.get<string>("GOOGLE_DOCUMENT_AI_PROJECT_ID")?.trim() &&
        this.config.get<string>("GOOGLE_DOCUMENT_AI_PROCESSOR_ID")?.trim(),
    );
    const openAiConfigured = Boolean(
      this.config.get<string>("OPENAI_API_KEY")?.trim() &&
        (this.config
          .get<string>("PRESCRIPTION_AI_EXTRACTOR")
          ?.trim()
          .toLowerCase() ?? "openai") === "openai",
    );
    const developmentOcrReady =
      ocrProvider === "development" &&
      this.config.get<string>("NODE_ENV") !== "production";

    return {
      data: {
        database: "reachable",
        manualPrescriptionEntry: "available",
        prescriptionAi: aiEnabled && openAiConfigured ? "ready" : "disabled",
        prescriptionOcr:
          cloudOcrEnabled && (developmentOcrReady || googleConfigured)
            ? "ready"
            : "fallback-only",
        service: "caremate-api",
        status: "ready",
      },
      meta: { serverTime: new Date().toISOString() },
    };
  }
}
