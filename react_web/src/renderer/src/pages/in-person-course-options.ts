import type { Course } from "../types";

const SAUDI_OFFSET_MS = 3 * 60 * 60 * 1000;

function getSaudiDayStart(instant: Date): number {
  const saudiTime = new Date(instant.getTime() + SAUDI_OFFSET_MS);
  saudiTime.setUTCHours(0, 0, 0, 0);
  return saudiTime.getTime() - SAUDI_OFFSET_MS;
}

export function getInPersonCourseOptions(
  courses: Course[],
  now: Date = new Date(),
): Course[] {
  const saudiDayStart = getSaudiDayStart(now);
  return courses.filter(
    (course) =>
      course.status === "published" &&
      new Date(course.endDate).getTime() >= saudiDayStart,
  );
}
