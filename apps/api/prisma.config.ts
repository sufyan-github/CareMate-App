import "dotenv/config";

import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
  },
  datasource: {
    url:
      process.env.PRISMA_MIGRATION_DATABASE_URL ??
      "file:./prisma/caremate-dev.db",
  },
});
