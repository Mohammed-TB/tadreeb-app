import { describe, expect, it } from "vitest";
import { formatCurrency, formatDate, getCourseTitle } from "./formatters";

describe("desktop formatters", () => {
  it("uses the institute's Yemeni-riyal label", () => {
    expect(formatCurrency(1250)).toMatch(/ر\.ي$/);
  });

  it("renders a placeholder for invalid dates", () => {
    expect(formatDate("not-a-date")).toBe("—");
  });

  it("supports populated and missing course references", () => {
    expect(getCourseTitle({ title: "إدارة المشاريع" })).toBe("إدارة المشاريع");
    expect(getCourseTitle("course-id")).toBe("دورة غير متاحة");
  });
});
