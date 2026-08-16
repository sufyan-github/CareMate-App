import type { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

import { AppModule } from "../src/app.module.js";

describe("GET /api/v1/health", () => {
  let app: INestApplication | undefined;

  beforeEach(async () => {
    process.env.TURSO_DATABASE_URL = ":memory:";
    delete process.env.TURSO_AUTH_TOKEN;

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix("/api/v1");
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
  });
});
