import { IsBoolean, IsIn, IsOptional, IsString, Equals } from "class-validator";

export class UpdateAccountPreferencesDto {
  @IsOptional()
  @IsIn(["bn-BD", "en-BD"])
  locale?: "bn-BD" | "en-BD";

  @IsOptional()
  @IsBoolean()
  showMedicineOnLockScreen?: boolean;

  @IsOptional()
  @IsBoolean()
  allowAnalytics?: boolean;

  @IsOptional()
  @IsBoolean()
  simpleMode?: boolean;

  @IsOptional()
  @IsBoolean()
  voicePromptsEnabled?: boolean;
}

export class RequestAccountDeletionDto {
  @IsString()
  @Equals("DELETE")
  confirmation!: "DELETE";
}
