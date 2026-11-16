const SAUDI_OFFSET_MS = 3 * 60 * 60 * 1000;
const DATE_ONLY_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const TIMEZONE_SUFFIX_PATTERN = /(?:Z|[+-]\d{2}:?\d{2})$/i;

export function parseCourseDate(value: Date | string): Date {
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) {
      throw new Error("Invalid course date");
    }
    return new Date(value.getTime());
  }

  const dateOnly = DATE_ONLY_PATTERN.exec(value);
  if (dateOnly) {
    const year = Number(dateOnly[1]);
    const month = Number(dateOnly[2]);
    const day = Number(dateOnly[3]);
    const utcDate = new Date(Date.UTC(year, month - 1, day));
    if (
      utcDate.getUTCFullYear() !== year ||
      utcDate.getUTCMonth() !== month - 1 ||
      utcDate.getUTCDate() !== day
    ) {
      throw new Error("Invalid course date");
    }
    return new Date(utcDate.getTime() - SAUDI_OFFSET_MS);
  }

  const dateWithSaudiOffset = TIMEZONE_SUFFIX_PATTERN.test(value)
    ? value
    : `${value}+03:00`;
  const parsed = new Date(dateWithSaudiOffset);
  if (Number.isNaN(parsed.getTime())) {
    throw new Error("Invalid course date");
  }
  return parsed;
}

export function getSaudiDayStart(instant: Date = new Date()): Date {
  const saudiTime = new Date(instant.getTime() + SAUDI_OFFSET_MS);
  return new Date(
    Date.UTC(
      saudiTime.getUTCFullYear(),
      saudiTime.getUTCMonth(),
      saudiTime.getUTCDate(),
    ) - SAUDI_OFFSET_MS,
  );
}
