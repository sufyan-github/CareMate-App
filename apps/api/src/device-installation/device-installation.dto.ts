import { IsIn, IsOptional, IsString, Length } from "class-validator";

export class RegisterDeviceInstallationDto {
  @IsString()
  @Length(1, 32)
  appVersion!: string;

  @IsString()
  @Length(1, 120)
  deviceName!: string;

  @IsIn(["bn-BD", "en-BD"])
  locale!: "bn-BD" | "en-BD";

  @IsIn(["ANDROID", "IOS"])
  platform!: "ANDROID" | "IOS";

  @IsOptional()
  @IsString()
  @Length(20, 4096)
  pushToken?: string;
}
