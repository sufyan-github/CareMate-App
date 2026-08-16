-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "phoneE164Encrypted" TEXT NOT NULL,
    "phoneLookupHash" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "locale" TEXT NOT NULL DEFAULT 'bn-BD',
    "tokenVersion" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "deletedAt" DATETIME
);

CREATE UNIQUE INDEX "User_phoneLookupHash_key" ON "User"("phoneLookupHash");

-- CreateTable
CREATE TABLE "OtpChallenge" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "phoneE164Encrypted" TEXT NOT NULL,
    "phoneLookupHash" TEXT NOT NULL,
    "purpose" TEXT NOT NULL,
    "locale" TEXT NOT NULL,
    "deviceInstallationId" TEXT NOT NULL,
    "codeHash" TEXT NOT NULL,
    "deliveryReference" TEXT,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "maxAttempts" INTEGER NOT NULL DEFAULT 5,
    "expiresAt" DATETIME NOT NULL,
    "resendAvailableAt" DATETIME NOT NULL,
    "consumedAt" DATETIME,
    "invalidatedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "OtpChallenge_phoneLookupHash_createdAt_idx" ON "OtpChallenge"("phoneLookupHash", "createdAt");
CREATE INDEX "OtpChallenge_deviceInstallationId_createdAt_idx" ON "OtpChallenge"("deviceInstallationId", "createdAt");

-- CreateTable
CREATE TABLE "AuthSession" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "installationId" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "appVersion" TEXT NOT NULL,
    "deviceName" TEXT NOT NULL,
    "tokenFamilyId" TEXT NOT NULL,
    "expiresAt" DATETIME NOT NULL,
    "revokedAt" DATETIME,
    "reuseDetectedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSeenAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AuthSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "AuthSession_tokenFamilyId_key" ON "AuthSession"("tokenFamilyId");
CREATE INDEX "AuthSession_userId_revokedAt_idx" ON "AuthSession"("userId", "revokedAt");

-- CreateTable
CREATE TABLE "RefreshCredential" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "sessionId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" DATETIME NOT NULL,
    "usedAt" DATETIME,
    "revokedAt" DATETIME,
    "replacedById" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "RefreshCredential_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "AuthSession" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "RefreshCredential_tokenHash_key" ON "RefreshCredential"("tokenHash");
CREATE INDEX "RefreshCredential_sessionId_revokedAt_idx" ON "RefreshCredential"("sessionId", "revokedAt");
