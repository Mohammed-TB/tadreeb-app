import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { BookOpenCheck, Search } from "lucide-react";
import { coursesApi } from "../api/services";
import { formatCurrency, formatDate, formatNumber } from "../formatters";
import { EmptyState, ErrorState, PageHeader, SkeletonRows, StatusBadge } from "../components/ui";

export function CoursesPage() {
  const [search, setSearch] = useState("");
  const courses = useQuery({
    queryKey: ["courses"],
    queryFn: coursesApi.getAll,
  });

  const filteredCourses = useMemo(() => {
    const query = search.trim().toLocaleLowerCase("ar");
    if (!query) return courses.data ?? [];
    return (courses.data ?? []).filter((course) =>
      `${course.title} ${course.category} ${course.location}`
        .toLocaleLowerCase("ar")
        .includes(query),
    );
  }, [courses.data, search]);

  return (
    <div className="page-stack">
      <PageHeader
        title="الدورات"
        description="تابع دورات معهدك وحالة النشر والسعة والتسجيل."
        action={
          <div className="page-count-chip">
            <BookOpenCheck size={16} />
            <span>{formatNumber(courses.data?.length ?? 0)} دورة</span>
          </div>
        }
      />

      <section className="panel table-panel">
        <div className="table-toolbar">
          <div>
            <h2>قائمة الدورات</h2>
            <span>الدورات مرتبّة من الأحدث إنشاءً.</span>
          </div>
          <label className="search-field">
            <Search size={17} />
            <input
              aria-label="ابحث عن دورة"
              onChange={(event) => setSearch(event.target.value)}
              placeholder="ابحث عن دورة أو تصنيف..."
              value={search}
            />
          </label>
        </div>

        {courses.isPending ? (
          <SkeletonRows />
        ) : courses.isError ? (
          <ErrorState
            message={courses.error.message}
            onRetry={() => void courses.refetch()}
          />
        ) : filteredCourses.length === 0 ? (
          <EmptyState
            description={search ? "جرّب كلمة بحث أخرى." : "ستظهر دورات معهدك هنا بعد إضافتها."}
            title={search ? "لا توجد نتائج" : "لا توجد دورات بعد"}
          />
        ) : (
          <div className="table-scroll">
            <table className="data-table courses-table">
              <thead>
                <tr>
                  <th>اسم الدورة</th>
                  <th>الحالة</th>
                  <th>الرسوم</th>
                  <th>المقاعد</th>
                  <th>تاريخ البداية</th>
                  <th>الموقع</th>
                </tr>
              </thead>
              <tbody>
                {filteredCourses.map((course) => {
                  const occupied = course.enrolledCount + course.reservedCount;
                  return (
                    <tr key={course._id}>
                      <td>
                        <div className="course-cell">
                          <div className="course-cell-icon"><BookOpenCheck size={17} /></div>
                          <div>
                            <strong>{course.title}</strong>
                            <span>{course.category}</span>
                          </div>
                        </div>
                      </td>
                      <td><StatusBadge status={course.status} /></td>
                      <td>
                        <strong className="latin-number">{formatCurrency(course.price)}</strong>
                        <small className="table-subtext">
                          العربون {formatCurrency(course.depositAmount)}
                        </small>
                      </td>
                      <td>
                        <strong className="latin-number">
                          {formatNumber(occupied)} / {formatNumber(course.capacity)}
                        </strong>
                        <small className="table-subtext">مسجلون / السعة</small>
                      </td>
                      <td>{formatDate(course.startDate)}</td>
                      <td>{course.location || "—"}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
        <div className="table-foot">
          <span>
            عرض {formatNumber(filteredCourses.length)} من {formatNumber(courses.data?.length ?? 0)} دورة
          </span>
          <span>تُحدّث البيانات تلقائيًا عند إعادة فتح الصفحة.</span>
        </div>
      </section>
    </div>
  );
}
