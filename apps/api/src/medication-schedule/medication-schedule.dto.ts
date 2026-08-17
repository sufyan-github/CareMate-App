import { Type } from "class-transformer";
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsPositive,
  IsString,
  Matches,
  Max,
  Min,
} from "class-validator";

const localDatePattern = /^\d{4}-\d{2}-\d{2}$/;
const localTimePattern = /^(?:[01]\d|2[0-3]):[0-5]\d$/;

export class CreateMedicationScheduleDto {
  @IsIn(["PREVIEW", "ACTIVATE"])
  activation!: "PREVIEW" | "ACTIVATE";

  @IsString()
  @Matches(localDatePattern)
  startDate!: string;

  @IsOptional()
  @IsString()
  @Matches(localDatePattern)
  endDate?: string;

  @IsOptional()
  @IsBoolean()
  openEnded?: boolean;

  @IsString()
  timezone!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(12)
  @Matches(localTimePattern, { each: true })
  times!: string[];

  @IsOptional()
  @IsIn(["DAILY", "WEEKLY"])
  recurrence?: "DAILY" | "WEEKLY";

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  daysOfWeek?: number[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(60)
  @ArrayUnique()
  @Matches(localDatePattern, { each: true })
  excludedDates?: string[];
}

export class DoseOccurrenceWindowDto {
  @Type(() => String)
  @IsString()
  @Matches(localDatePattern)
  from!: string;

  @Type(() => String)
  @IsString()
  @Matches(localDatePattern)
  to!: string;
}

export class UpdateMedicationScheduleDto {
  @IsInt()
  @IsPositive()
  expectedVersion!: number;

  @IsOptional()
  @IsString()
  @Matches(localDatePattern)
  startDate?: string;

  @IsOptional()
  @IsString()
  @Matches(localDatePattern)
  endDate?: string;

  @IsOptional()
  @IsBoolean()
  openEnded?: boolean;

  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(12)
  @Matches(localTimePattern, { each: true })
  times?: string[];

  @IsOptional()
  @IsIn(["DAILY", "WEEKLY"])
  recurrence?: "DAILY" | "WEEKLY";

  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  daysOfWeek?: number[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(60)
  @ArrayUnique()
  @Matches(localDatePattern, { each: true })
  excludedDates?: string[];

  @IsOptional()
  @IsString()
  timezone?: string;
}

export class ScheduleCommandDto {
  @IsInt()
  @IsPositive()
  expectedVersion!: number;
}
