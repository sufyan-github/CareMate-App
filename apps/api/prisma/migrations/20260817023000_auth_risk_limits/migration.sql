ALTER TABLE "OtpChallenge" ADD COLUMN "requestIpHash" TEXT NOT NULL DEFAULT '';

CREATE INDEX "OtpChallenge_requestIpHash_createdAt_idx" ON "OtpChallenge"("requestIpHash", "createdAt");
