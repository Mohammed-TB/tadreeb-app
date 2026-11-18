export function normalizeFourPartName(value: unknown): string | null {
  if (typeof value !== "string") return null;

  const normalized = value.trim().replace(/\s+/g, " ");
  if (normalized.split(" ").length < 4) return null;
  return normalized;
}
