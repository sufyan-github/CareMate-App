import { Type } from "class-transformer";
import {
  IsIn,
  IsNotEmpty,
  IsString,
  Length,
  MaxLength,
  Matches,
  ValidateNested,
} from "class-validator";

export class RequestOtpDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(32)
  phoneNumber!: string;

  @IsIn(["LOGIN"])
  purpose!: "LOGIN";

  @IsIn(["bn-BD", "en-BD"])
  locale!: "bn-BD" | "en-BD";

  @IsString()
  @Length(16, 64)
  deviceInstallationId!: string;
}

export class AuthDeviceDto {
  @IsString()
  @Length(16, 64)
  installationId!: string;

  @IsIn(["ANDROID"])
  platform!: "ANDROID";

  @IsString()
  @Length(1, 32)
  appVersion!: string;

  @IsString()
  @Length(1, 80)
  deviceName!: string;
}

export class VerifyOtpDto {
  @IsString()
  @Length(16, 64)
  challengeId!: string;

  @IsString()
  @Length(6, 8)
  @Matches(/^\d{6}$/)
  otp!: string;

  @ValidateNested()
  @Type(() => AuthDeviceDto)
  device!: AuthDeviceDto;
}

export class RefreshTokenDto {
  @IsString()
  @Length(40, 512)
  refreshToken!: string;
}
