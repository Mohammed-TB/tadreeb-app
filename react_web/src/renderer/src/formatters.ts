const numberFormatter = new Intl.NumberFormat("ar-YE", {
  maximumFractionDigits: 0,
});

const dateFormatter = new Intl.DateTimeFormat("ar-YE", {
  day: "numeric",
  month: "short",
  year: "numeric",
});

export function formatNumber(value: number): string {
  return numberFormatter.format(Number.isFinite(value) ? value : 0);
}

export function formatCurrency(value: number): string {
  return `${formatNumber(value)} ر.ي`;
}

export function formatDate(value: string | Date): string {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return dateFormatter.format(date);
}

export function getCourseTitle(
  course: { title: string } | string | null | undefined,
): string {
  return typeof course === "object" && course !== null ? course.title : "دورة غير متاحة";
}
