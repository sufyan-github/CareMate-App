ALTER TABLE "DeviceInstallation"
  ADD COLUMN "locale" TEXT NOT NULL DEFAULT 'bn-BD';

ALTER TABLE "DeviceInstallation"
  ADD COLUMN "pushToken" TEXT;
