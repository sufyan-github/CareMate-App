import { AuthError } from "./auth-error.js";
import { HttpStatus } from "@nestjs/common";

export function normalizeBangladeshPhoneNumber(input: string): string {
  const compact = input.replace(/[\s()-]/g, "");
  let local: string;

  if (/^\+8801[3-9]\d{8}$/.test(compact)) {
    return compact;
  }
  if (/^8801[3-9]\d{8}$/.test(compact)) {
    return `+${compact}`;
  }
  if (/^01[3-9]\d{8}$/.test(compact)) {
    local = compact.slice(1);
  } else if (/^1[3-9]\d{8}$/.test(compact)) {
    local = compact;
  } else {
    throw new AuthError(
      HttpStatus.BAD_REQUEST,
      "PHONE_NUMBER_INVALID",
      "Enter a valid Bangladesh mobile number.",
    );
  }

  return `+880${local}`;
}

export function maskPhoneNumber(phoneNumber: string): string {
  return `••••••${phoneNumber.slice(-4)}`;
}
