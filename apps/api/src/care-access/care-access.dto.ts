import { Type } from "class-transformer";
import {
  IsBoolean,
  IsString,
  MaxLength,
  ValidateNested,
} from "class-validator";

export class CarePermissionsDto {
  @IsBoolean()
  canViewMedicationPlan!: boolean;

  @IsBoolean()
  canReceiveMissedDoseAlerts!: boolean;
}

export class CreateCareInvitationDto {
  @IsString()
  @MaxLength(32)
  phoneNumber!: string;

  @ValidateNested()
  @Type(() => CarePermissionsDto)
  permissions!: CarePermissionsDto;
}
