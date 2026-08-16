import { IsOptional, IsString, MaxLength } from "class-validator";

export class ExtractPrescriptionDto {
  @IsOptional()
  @IsString()
  @MaxLength(10_000)
  localOcrText?: string;
}
