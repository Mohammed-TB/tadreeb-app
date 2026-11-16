import assert from "node:assert/strict";
import test from "node:test";
import { getSaudiDayStart, parseCourseDate } from "./course-date";

test("parses a date-only value as midnight in Saudi Arabia", () => {
  assert.equal(
    parseCourseDate("2026-11-16").toISOString(),
    "2026-11-15T21:00:00.000Z",
  );
});

test("interprets legacy timezone-less timestamps as Saudi local time", () => {
  assert.equal(
    parseCourseDate("2026-11-16T00:00:00.000").toISOString(),
    "2026-11-15T21:00:00.000Z",
  );
});

test("keeps explicitly zoned timestamps unchanged", () => {
  assert.equal(
    parseCourseDate("2026-11-15T21:00:00.000Z").toISOString(),
    "2026-11-15T21:00:00.000Z",
  );
});

test("uses Saudi midnight as the inclusive end-date cutoff", () => {
  const endDate = parseCourseDate("2026-11-16");
  const duringEndDate = new Date("2026-11-16T20:59:59.999Z");
  const nextSaudiDay = new Date("2026-11-16T21:00:00.000Z");

  assert.ok(endDate >= getSaudiDayStart(duringEndDate));
  assert.ok(endDate < getSaudiDayStart(nextSaudiDay));
});

test("rejects invalid date-only calendar values", () => {
  assert.throws(() => parseCourseDate("2026-02-30"), /Invalid course date/);
});
