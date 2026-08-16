import { Controller, Get, ServiceUnavailableException } from "@nestjs/common";

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
  constructor(private readonly database: DatabaseService) {}

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
}
