CREATE TABLE "DeviceInstallation" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "userId" TEXT NOT NULL,
  "installationId" TEXT NOT NULL,
  "platform" TEXT NOT NULL,
  "appVersion" TEXT NOT NULL,
  "deviceName" TEXT NOT NULL,
  "status" TEXT NOT NULL DEFAULT 'ACTIVE',
  "registeredAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "lastSeenAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "revokedAt" DATETIME,
  CONSTRAINT "DeviceInstallation_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User" ("id")
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "DeviceInstallation_userId_installationId_key"
  ON "DeviceInstallation"("userId", "installationId");
CREATE INDEX "DeviceInstallation_installationId_status_idx"
  ON "DeviceInstallation"("installationId", "status");
