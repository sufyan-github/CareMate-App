import { Injectable, type OnModuleDestroy } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { PrismaLibSql } from "@prisma/adapter-libsql";

import { PrismaClient } from "../generated/prisma/client.js";

@Injectable()
export class DatabaseService extends PrismaClient implements OnModuleDestroy {
  constructor(config: ConfigService) {
    const url = config.get<string>("TURSO_DATABASE_URL") ?? ":memory:";
    const authToken = config.get<string>("TURSO_AUTH_TOKEN");
    const adapter = new PrismaLibSql({
      url,
      ...(authToken ? { authToken } : {}),
    });

    super({ adapter });
  }

  async isReachable(): Promise<boolean> {
    const rows = await this.$queryRawUnsafe<
      Array<{ connectivity_check: number }>
    >("SELECT 1 AS connectivity_check");

    return rows[0]?.connectivity_check === 1;
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
