import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { AppModule } from "../src/app.module.js";
import { configureApp } from "../src/configure-app.js";

describe("GET /api/v1/health", () => {
  let app: INestApplication | undefined;

  beforeEach(async () => {
    process.env.TURSO_DATABASE_URL = ":memory:";
    process.env.PRESCRIPTION_AI_ENABLED = "false";
    process.env.PRESCRIPTION_OCR_PROVIDER = "development";
    delete process.env.TURSO_AUTH_TOKEN;

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterEach(async () => {
    await app?.close();
  });

  it("reports that the API and database are reachable", async () => {
    const response = await request(app!.getHttpServer())
      .get("/api/v1/health")
      .expect(200);

    expect(response.body).toEqual({
      data: {
        database: "reachable",
        service: "caremate-api",
        status: "ok",
      },
      meta: {
        serverTime: expect.any(String),
      },
    });
    expect(response.headers["x-request-id"]).toMatch(/^req_[A-Z0-9]+$/u);
  });

  it("reports provider kill-switch readiness without exposing secrets", async () => {
    const response = await request(app!.getHttpServer())
      .get("/api/v1/health/readiness")
      .set("x-request-id", "competition_check_01")
      .expect(200);

    expect(response.headers["x-request-id"]).toBe("competition_check_01");
    expect(response.body).toEqual({
      data: {
        database: "reachable",
        manualPrescriptionEntry: "available",
        prescriptionAi: "disabled",
        prescriptionOcr: "ready",
        service: "caremate-api",
        status: "ready",
      },
      meta: { serverTime: expect.any(String) },
    });
    expect(JSON.stringify(response.body)).not.toContain("API_KEY");
  });
});
