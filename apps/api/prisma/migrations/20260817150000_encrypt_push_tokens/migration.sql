PRAGMA foreign_keys=OFF;

CREATE TABLE "new_DeviceInstallation" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "userId" TEXT NOT NULL,
  "installationId" TEXT NOT NULL,
  "platform" TEXT NOT NULL,
  "appVersion" TEXT NOT NULL,
  "deviceName" TEXT NOT NULL,
  "locale" TEXT NOT NULL DEFAULT 'bn-BD',
  "pushTokenEncrypted" TEXT,
  "pushTokenLookupHash" TEXT,
  "pushStatus" TEXT NOT NULL DEFAULT 'UNREGISTERED',
  "status" TEXT NOT NULL DEFAULT 'ACTIVE',
  "registeredAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lastSeenAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "revokedAt" DATETIME,
  CONSTRAINT "DeviceInstallation_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User" ("id")
    ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO "new_DeviceInstallation" (
  "id", "userId", "installationId", "platform", "appVersion", "deviceName",
  "locale", "status", "registeredAt", "lastSeenAt", "revokedAt"
)
SELECT
  "id", "userId", "installationId", "platform", "appVersion", "deviceName",
  "locale", "status", "registeredAt", "lastSeenAt", "revokedAt"
FROM "DeviceInstallation";

DROP TABLE "DeviceInstallation";
ALTER TABLE "new_DeviceInstallation" RENAME TO "DeviceInstallation";

CREATE UNIQUE INDEX "DeviceInstallation_userId_installationId_key"
  ON "DeviceInstallation"("userId", "installationId");
CREATE UNIQUE INDEX "DeviceInstallation_pushTokenLookupHash_key"
  ON "DeviceInstallation"("pushTokenLookupHash")
  WHERE "pushTokenLookupHash" IS NOT NULL;
CREATE INDEX "DeviceInstallation_installationId_status_idx"
  ON "DeviceInstallation"("installationId", "status");

PRAGMA foreign_keys=ON;
