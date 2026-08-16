import { Type } from "class-transformer";
import {
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  Length,
  MaxLength,
  ValidateNested,
} from "class-validator";

const medicationForms = [
  "TABLET",
  "CAPSULE",
  "SYRUP",
  "INJECTION",
  "DROPS",
  "OTHER",
] as const;
const mealRelations = ["BEFORE", "WITH", "AFTER", "UNSPECIFIED"] as const;
const routes = ["ORAL", "TOPICAL", "INHALED", "INJECTED", "OTHER"] as const;

export class CreatePatientProfileDto {
  @IsString()
  @Length(1, 80)
  displayName!: string;

  @IsString()
  @Length(1, 80)
  timezone!: string;
}

export class UpdatePatientProfileDto {
  @IsInt()
  @IsPositive()
  expectedVersion!: number;

  @IsOptional()
  @IsString()
  @Length(1, 80)
  displayName?: string;

  @IsOptional()
  @IsString()
  @Length(1, 80)
  timezone?: string;
}

export class DoseInstructionDto {
  @IsNumber({ maxDecimalPlaces: 3 })
  @IsPositive()
  quantityValue!: number;

  @IsString()
  @Length(1, 24)
  quantityUnit!: string;

  @IsIn(routes)
  route!: (typeof routes)[number];

  @IsIn(mealRelations)
  mealRelation!: (typeof mealRelations)[number];

  @IsOptional()
  @IsString()
  @MaxLength(500)
  sourceText?: string;
}

export class CreateMedicationDto {
  @IsString()
  @Length(1, 120)
  displayName!: string;

  @IsOptional()
  @IsString()
  @Length(1, 120)
  normalizedName?: string;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @IsPositive()
  strengthValue?: number;

  @IsOptional()
  @IsString()
  @Length(1, 24)
  strengthUnit?: string;

  @IsIn(medicationForms)
  form!: (typeof medicationForms)[number];

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  @ValidateNested()
  @Type(() => DoseInstructionDto)
  instructions!: DoseInstructionDto;
}

export class UpdateMedicationDto {
  @IsInt()
  @IsPositive()
  expectedVersion!: number;

  @IsOptional()
  @IsString()
  @Length(1, 120)
  displayName?: string;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @IsPositive()
  strengthValue?: number;

  @IsOptional()
  @IsString()
  @Length(1, 24)
  strengthUnit?: string;

  @IsOptional()
  @IsIn(medicationForms)
  form?: (typeof medicationForms)[number];

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  @IsOptional()
  @IsIn(["ACTIVE", "PAUSED", "ENDED"])
  status?: "ACTIVE" | "PAUSED" | "ENDED";

  @IsOptional()
  @ValidateNested()
  @Type(() => DoseInstructionDto)
  instructions?: DoseInstructionDto;
}
