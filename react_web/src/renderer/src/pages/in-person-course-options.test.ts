import { describe, expect, it } from "vitest";
import type { Course } from "../types";
import { getInPersonCourseOptions } from "./in-person-course-options";

function createCourse(overrides: Partial<Course> = {}): Course {
  return {
    _id: "course-1",
    title: "دورة تدريبية",
    description: "وصف الدورة",
    category: "إدارة",
    price: 1000,
    depositAmount: 100,
    requiresEnglishName: false,
    capacity: 20,
    enrolledCount: 0,
    reservedCount: 0,
    startDate: "2026-11-24T06:00:00.000Z",
    endDate: "2026-11-27T06:00:00.000Z",
    status: "published",
    location: "المعهد",
    whatWillLearn: [],
    features: [],
    ...overrides,
  };
}

describe("in-person course options", () => {
  it("includes published courses that are still running", () => {
    const ongoing = createCourse();
    const ended = createCourse({
      _id: "course-ended",
      endDate: "2026-11-24T20:59:00.000Z",
    });
    const draft = createCourse({
      _id: "course-draft",
      status: "draft",
    });

    expect(
      getInPersonCourseOptions(
        [ongoing, ended, draft],
        new Date("2026-11-25T05:00:00.000Z"),
      ),
    ).toEqual([ongoing]);
  });
});
