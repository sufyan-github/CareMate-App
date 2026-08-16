import { Injectable, type OnModuleDestroy } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { PrismaLibSql } from "@prisma/adapter-libsql";
import { randomUUID } from "node:crypto";
import { unlink } from "node:fs/promises";

import { PrismaClient } from "../generated/prisma/client.js";

@Injectable()
export class DatabaseService extends PrismaClient implements OnModuleDestroy {
  private readonly ephemeralDatabasePath: string | undefined;

  constructor(config: ConfigService) {
    const configuredUrl =
      config.get<string>("TURSO_DATABASE_URL") ?? ":memory:";
    const ephemeralDatabasePath =
      configuredUrl === ":memory:"
        ? `/tmp/caremate-${process.pid}-${randomUUID()}.db`
        : undefined;
    const url =
      ephemeralDatabasePath === undefined
        ? configuredUrl
        : `file:${ephemeralDatabasePath}`;
    const authToken = config.get<string>("TURSO_AUTH_TOKEN");
    const adapter = new PrismaLibSql({
      url,
      ...(authToken ? { authToken } : {}),
    });

    super({ adapter });
    this.ephemeralDatabasePath = ephemeralDatabasePath;
  }

  async isReachable(): Promise<boolean> {
    const rows = await this.$queryRawUnsafe<
      Array<{ connectivity_check: number }>
    >("SELECT 1 AS connectivity_check");

    return rows[0]?.connectivity_check === 1;
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
    if (this.ephemeralDatabasePath) {
      await unlink(this.ephemeralDatabasePath).catch(() => undefined);
    }
  }
}
