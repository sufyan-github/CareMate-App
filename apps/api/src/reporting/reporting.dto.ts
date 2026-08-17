import { Type } from "class-transformer";
import { IsString, Matches } from "class-validator";

const localDatePattern = /^\d{4}-\d{2}-\d{2}$/;

export class IndicatorWindowDto {
  @Type(() => String)
  @IsString()
  @Matches(localDatePattern)
  from!: string;

  @Type(() => String)
  @IsString()
  @Matches(localDatePattern)
  to!: string;
}
