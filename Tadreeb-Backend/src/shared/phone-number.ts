export const E164_PHONE_PATTERN = /^\+[1-9]\d{1,14}$/;

export function isValidE164Phone(value: unknown): value is string {
  return typeof value === "string" && E164_PHONE_PATTERN.test(value);
}
