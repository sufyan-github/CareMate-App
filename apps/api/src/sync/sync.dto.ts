import { Type } from "class-transformer";
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsISO8601,
  IsObject,
  IsOptional,
  IsString,
  Length,
  Max,
  Min,
  ValidateNested,
} from "class-validator";

class SyncMutationPayloadDto {
  @IsOptional()
  @IsString()
  @Length(1, 280)
  reason?: string;

  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(60)
  snoozeMinutes?: number;
}

export class SyncMutationDto {
  @IsString()
  @Length(1, 64)
  entityId!: string;

  @IsIn(["DOSE_OCCURRENCE"])
  entityType!: "DOSE_OCCURRENCE";

  @IsISO8601({ strict: true })
  clientAt!: string;

  @IsIn(["CONFIRM", "SNOOZE", "SKIP"])
  command!: "CONFIRM" | "SNOOZE" | "SKIP";

  @IsInt()
  @Min(1)
  baseVersion!: number;

  @IsString()
  @Length(20, 64)
  installationId!: string;

  @IsString()
  @Length(26, 64)
  mutationId!: string;

  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => SyncMutationPayloadDto)
  payload?: SyncMutationPayloadDto;
}

export class SyncMutationBatchDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => SyncMutationDto)
  mutations!: SyncMutationDto[];
}
