import { Type } from "class-transformer";
import {
  IsIn,
  IsInt,
  IsISO8601,
  IsOptional,
  IsPositive,
  IsString,
  Length,
  Max,
  Min,
  ValidateNested,
} from "class-validator";

export class DoseCommandPayloadDto {
  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(60)
  snoozeMinutes?: number;

  @IsOptional()
  @IsString()
  @Length(1, 280)
  reason?: string;
}

export class DoseCommandDto {
  @IsIn(["CONFIRM", "SNOOZE", "SKIP"])
  command!: "CONFIRM" | "SNOOZE" | "SKIP";

  @IsInt()
  @IsPositive()
  expectedVersion!: number;

  @IsString()
  @Length(20, 80)
  clientMutationId!: string;

  @IsISO8601({ strict: true })
  clientAt!: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => DoseCommandPayloadDto)
  payload?: DoseCommandPayloadDto;
}
