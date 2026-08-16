import { Injectable, type OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";

import { DatabaseService } from "./database.service.js";

@Injectable()
export class DatabaseMigrationService implements OnModuleInit {
  constructor(
    private readonly config: ConfigService,
    private readonly database: DatabaseService,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.database.$executeRawUnsafe(`
      CREATE TABLE IF NOT EXISTS "_CareMateMigration" (
        "id" TEXT NOT NULL PRIMARY KEY,
        "appliedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    `);

    const migrationsPath =
      this.config.get<string>("PRISMA_MIGRATIONS_PATH") ??
      join(process.cwd(), "prisma", "migrations");
    const entries = await readdir(migrationsPath, { withFileTypes: true });
    const migrationIds = entries
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort();

    for (const migrationId of migrationIds) {
      const applied = await this.database.$queryRawUnsafe<
        Array<{ id: string }>
      >(
        `SELECT "id" FROM "_CareMateMigration" WHERE "id" = ? LIMIT 1`,
        migrationId,
      );
      if (applied.length > 0) {
        continue;
      }

      const sql = await readFile(
        join(migrationsPath, migrationId, "migration.sql"),
        "utf8",
      );
      const statements = sql
        .split(";")
        .map((statement) => statement.trim())
        .filter((statement) => statement.length > 0);

      await this.database.$transaction(async (transaction) => {
        for (const statement of statements) {
          await transaction.$executeRawUnsafe(statement);
        }
        await transaction.$executeRawUnsafe(
          `INSERT INTO "_CareMateMigration" ("id") VALUES (?)`,
          migrationId,
        );
      });
    }
  }
}
