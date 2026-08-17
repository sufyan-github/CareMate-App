import type { ConfigService } from "@nestjs/config";

export function featureEnabled(
  config: ConfigService,
  name: string,
  defaultValue = true,
): boolean {
  const value = config.get<string>(name)?.trim().toLowerCase();
  if (value === undefined || value === "") return defaultValue;
  return !["0", "false", "off", "disabled"].includes(value);
}
