import {
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  Length,
  Max,
  MaxLength,
  Min,
} from "class-validator";

export class CreateStockAdjustmentDto {
  @IsNumber({ maxDecimalPlaces: 3 })
  delta!: number;

  @IsIn(["OPENING", "RESTOCK", "CORRECTION"])
  reason!: "OPENING" | "RESTOCK" | "CORRECTION";

  @IsString()
  @Length(20, 100)
  idempotencyKey!: string;

  @IsString()
  @Length(1, 32)
  quantityUnit!: string;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  note?: string;
}

export class UpdateInventoryPositionDto {
  @IsInt()
  @IsPositive()
  expectedVersion!: number;

  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0)
  @Max(1_000_000)
  lowStockThreshold!: number;
}
