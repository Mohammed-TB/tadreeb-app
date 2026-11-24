import { useMemo, useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  BookOpenCheck,
  Check,
  CirclePlus,
  Pencil,
  Plus,
  Search,
  Trash2,
  X,
} from "lucide-react";
import { NumericFormat } from "react-number-format";
import { coursesApi } from "../api/services";
import { formatCurrency, formatDate, formatNumber } from "../formatters";
import {
  EmptyState,
  ErrorState,
  PageHeader,
  SkeletonRows,
  StatusBadge,
} from "../components/ui";
import type { Course, CourseInput } from "../types";

type CourseAction = "publish" | "close" | "reopen" | "delete";

const courseCategories = ["محاسبة", "إدارة", "البرمجة", "تصميم", "خياطة", "أخرى"];

function toLocalInput(value?: string) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return new Date(date.getTime() - date.getTimezoneOffset() * 60_000)
    .toISOString()
    .slice(0, 16);
}

export function CoursesPage() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [editorOpen, setEditorOpen] = useState(false);
  const [editingCourse, setEditingCourse] = useState<Course | null>(null);
  const [feedback, setFeedback] = useState("");

  const courses = useQuery({
    queryKey: ["courses"],
    queryFn: coursesApi.getAll,
  });

  const refreshData = async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ["courses"] }),
      queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
    ]);
  };

  const saveCourse = useMutation({
    mutationFn: ({
      courseId,
      input,
      image,
    }: {
      courseId?: string;
      input: CourseInput;
      image?: File;
    }) =>
      courseId
        ? coursesApi.update(courseId, input, image)
        : coursesApi.create(input, image),
    onSuccess: async (_course, variables) => {
      await refreshData();
      setEditorOpen(false);
      setEditingCourse(null);
      setFeedback(variables.courseId ? "تم تحديث بيانات الدورة." : "تمت إضافة الدورة كمسودة.");
    },
    onError: (error) => setFeedback(error.message),
  });

  const courseAction = useMutation<
    Course | { id: string },
    Error,
    { courseId: string; action: CourseAction }
  >({
    mutationFn: ({
      courseId,
      action,
    }: {
      courseId: string;
      action: CourseAction;
    }) => {
      if (action === "publish") return coursesApi.publish(courseId);
      if (action === "close") return coursesApi.close(courseId);
      if (action === "reopen") return coursesApi.reopen(courseId);
      return coursesApi.delete(courseId);
    },
    onSuccess: async (_result, variables) => {
      await refreshData();
      const labels: Record<CourseAction, string> = {
        publish: "تم نشر الدورة.",
        close: "تم إغلاق التسجيل في الدورة.",
        reopen: "تمت إعادة فتح التسجيل.",
        delete: "تم حذف المسودة.",
      };
      setFeedback(labels[variables.action]);
    },
    onError: (error) => setFeedback(error.message),
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

  const openNewCourse = () => {
    setFeedback("");
    setEditingCourse(null);
    setEditorOpen(true);
  };

  const openEditCourse = (course: Course) => {
    setFeedback("");
    setEditingCourse(course);
    setEditorOpen(true);
  };

  const runAction = (course: Course, action: CourseAction) => {
    if (
      action === "delete" &&
      !window.confirm(`هل تريد حذف مسودة «${course.title}»؟ لا يمكن التراجع عن هذا الإجراء.`)
    ) {
      return;
    }
    setFeedback("");
    courseAction.mutate({ courseId: course._id, action });
  };

  return (
    <div className="page-stack">
      <PageHeader
        title="الدورات"
        description="أضف الدورات، حدّث بياناتها، وتحكم في فتح التسجيل وإغلاقه."
        action={
          <button className="button button-primary" onClick={openNewCourse}>
            <CirclePlus size={17} />
            إضافة دورة
          </button>
        }
      />

      <section className="metrics-grid">
        <div className="metric-card">
          <div className="metric-icon metric-icon-green"><BookOpenCheck size={20} /></div>
          <div className="metric-copy">
            <span>إجمالي الدورات</span>
            <strong>{formatNumber(courses.data?.length ?? 0)}</strong>
            <small>جميع حالات الدورات</small>
          </div>
        </div>
        <div className="metric-card">
          <div className="metric-icon metric-icon-sage"><Check size={20} /></div>
          <div className="metric-copy">
            <span>دورات منشورة</span>
            <strong>{formatNumber(courses.data?.filter((item) => item.status === "published").length ?? 0)}</strong>
            <small>متاحة للتسجيل</small>
          </div>
        </div>
        <div className="metric-card">
          <div className="metric-icon metric-icon-gold"><Pencil size={19} /></div>
          <div className="metric-copy">
            <span>مسودات</span>
            <strong>{formatNumber(courses.data?.filter((item) => item.status === "draft").length ?? 0)}</strong>
            <small>يمكن تعديلها أو نشرها</small>
          </div>
        </div>
        <div className="metric-card">
          <div className="metric-icon metric-icon-coral"><X size={19} /></div>
          <div className="metric-copy">
            <span>تسجيل مغلق</span>
            <strong>{formatNumber(courses.data?.filter((item) => item.status === "closed").length ?? 0)}</strong>
            <small>يمكن إعادة فتحها إذا توفرت الشروط</small>
          </div>
        </div>
      </section>

      {feedback && (
        <div className="toast-message" role="status">
          <span>{feedback}</span>
          <button aria-label="إغلاق الرسالة" className="icon-button" onClick={() => setFeedback("")}>
            <X size={15} />
          </button>
        </div>
      )}

      <section className="panel table-panel">
        <div className="table-toolbar">
          <div>
            <h2>قائمة الدورات</h2>
            <span>الدورات مرتبة من الأحدث إنشاءً.</span>
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
            description={search ? "جرّب كلمة بحث أخرى." : "أضف أول دورة لمعهدك من الزر أعلاه."}
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
                  <th>الإجراءات</th>
                </tr>
              </thead>
              <tbody>
                {filteredCourses.map((course) => {
                  const occupied = course.enrolledCount + course.reservedCount;
                  return (
                    <tr key={course._id}>
                      <td>
                        <div className="course-cell">
                          {course.image ? (
                            <img alt="" className="course-thumb" src={course.image} />
                          ) : (
                            <div className="course-cell-icon"><BookOpenCheck size={17} /></div>
                          )}
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
                      <td>
                        <div className="course-actions">
                          {course.status === "draft" && (
                            <button
                              aria-label={`تعديل ${course.title}`}
                              className="table-action"
                              onClick={() => openEditCourse(course)}
                            >
                              <Pencil size={14} /> تعديل
                            </button>
                          )}
                          {course.status === "draft" && (
                            <>
                              <button
                                className="table-action"
                                disabled={courseAction.isPending}
                                onClick={() => runAction(course, "publish")}
                              >
                                <Check size={14} /> نشر
                              </button>
                              {occupied === 0 && (
                                <button
                                  aria-label={`حذف ${course.title}`}
                                  className="table-action table-action-danger"
                                  disabled={courseAction.isPending}
                                  onClick={() => runAction(course, "delete")}
                                >
                                  <Trash2 size={14} />
                                </button>
                              )}
                            </>
                          )}
                          {course.status === "published" && (
                            <button
                              className="table-action"
                              disabled={courseAction.isPending}
                              onClick={() => runAction(course, "close")}
                            >
                              إغلاق التسجيل
                            </button>
                          )}
                          {course.status === "closed" && (
                            <button
                              className="table-action"
                              disabled={courseAction.isPending}
                              onClick={() => runAction(course, "reopen")}
                            >
                              إعادة الفتح
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
        <div className="table-foot">
          <span>عرض {formatNumber(filteredCourses.length)} من {formatNumber(courses.data?.length ?? 0)} دورة</span>
          <span>النشر وإعادة الفتح يخضعان لشروط الخادم والسعة والتاريخ.</span>
        </div>
      </section>

      {editorOpen && (
        <CourseEditor
          course={editingCourse}
          isSaving={saveCourse.isPending}
          onClose={() => {
            setEditorOpen(false);
            setEditingCourse(null);
          }}
          onSave={(input, image) => {
            setFeedback("");
            saveCourse.mutate({
              courseId: editingCourse?._id,
              input,
              image,
            });
          }}
        />
      )}
    </div>
  );
}

function CourseEditor({
  course,
  isSaving,
  onClose,
  onSave,
}: {
  course: Course | null;
  isSaving: boolean;
  onClose(): void;
  onSave(input: CourseInput, image?: File): void;
}) {
  const [title, setTitle] = useState(course?.title ?? "");
  const [description, setDescription] = useState(course?.description ?? "");
  const [category, setCategory] = useState(course?.category ?? "");
  const [price, setPrice] = useState(course?.price.toString() ?? "");
  const [depositAmount, setDepositAmount] = useState(course?.depositAmount.toString() ?? "");
  const [capacity, setCapacity] = useState(course?.capacity.toString() ?? "");
  const [startDate, setStartDate] = useState(toLocalInput(course?.startDate));
  const [endDate, setEndDate] = useState(toLocalInput(course?.endDate));
  const [location, setLocation] = useState(course?.location ?? "");
  const [requiresEnglishName, setRequiresEnglishName] = useState(course?.requiresEnglishName ?? false);
  const [whatWillLearn, setWhatWillLearn] = useState(course?.whatWillLearn ?? []);
  const [features, setFeatures] = useState(course?.features ?? []);
  const [image, setImage] = useState<File>();
  const [error, setError] = useState("");
  const [activeTab, setActiveTab] = useState<"basic" | "details">("basic");

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");

    if (title.trim().length < 3) {
      setActiveTab("basic");
      setError("اسم الدورة يجب أن يتكون من 3 أحرف على الأقل.");
      return;
    }
    if (!description.trim() || !category.trim() || !location.trim()) {
      setActiveTab(!location.trim() ? "details" : "basic");
      setError("أكمل اسم الدورة والتصنيف والوصف والموقع.");
      return;
    }
    if (!price || !depositAmount || !capacity) {
      setActiveTab("basic");
      setError("أدخل السعر والعربون والسعة.");
      return;
    }

    const numericPrice = Number(price);
    const numericDeposit = Number(depositAmount);
    const numericCapacity = Number(capacity);
    const start = new Date(startDate);
    const end = new Date(endDate);

    if (!Number.isFinite(numericPrice) || numericPrice < 0) {
      setActiveTab("basic");
      setError("أدخل سعرًا صحيحًا للدورة.");
      return;
    }
    if (!Number.isFinite(numericDeposit) || numericDeposit < 0 || numericDeposit > numericPrice) {
      setActiveTab("basic");
      setError("يجب أن يكون العربون بين صفر وسعر الدورة.");
      return;
    }
    if (!Number.isInteger(numericCapacity) || numericCapacity < 1) {
      setActiveTab("basic");
      setError("السعة يجب أن تكون عددًا صحيحًا لا يقل عن طالب واحد.");
      return;
    }
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || end <= start) {
      setActiveTab("details");
      setError("تحقق من تاريخ البداية والنهاية.");
      return;
    }
    if (start <= new Date()) {
      setActiveTab("details");
      setError("تاريخ بداية الدورة يجب أن يكون في المستقبل.");
      return;
    }
    if (image && image.size > 5 * 1024 * 1024) {
      setActiveTab("basic");
      setError("حجم الصورة يجب ألا يتجاوز 5 ميجابايت.");
      return;
    }
    if (
      image &&
      !["image/jpeg", "image/png", "image/webp"].includes(image.type)
    ) {
      setActiveTab("basic");
      setError("صيغة الصورة المدعومة هي JPG أو PNG أو WEBP.");
      return;
    }

    onSave(
      {
        title: title.trim(),
        description: description.trim(),
        category: category.trim(),
        price: numericPrice,
        depositAmount: numericDeposit,
        capacity: numericCapacity,
        startDate: start.toISOString(),
        endDate: end.toISOString(),
        location: location.trim(),
        requiresEnglishName,
        whatWillLearn,
        features,
      },
      image,
    );
  };

  return (
    <div className="form-dialog-backdrop" onMouseDown={(event) => {
      if (event.target === event.currentTarget && !isSaving) onClose();
    }}>
      <section aria-label={course ? "تعديل الدورة" : "إضافة دورة"} aria-modal="true" className="form-dialog" role="dialog">
        <div className="form-dialog-header">
          <div>
            <span className="panel-kicker">{course ? "تحديث بيانات الدورة" : "دورة جديدة"}</span>
            <h2 className="course-editor-title">
              {title.trim() || (course ? course.title : "إضافة دورة إلى المعهد")}
            </h2>
          </div>
          <button aria-label="إغلاق" className="icon-button" disabled={isSaving} onClick={onClose}>
            <X size={20} />
          </button>
        </div>
        <form className="form-dialog-body" onSubmit={submit}>
          <div aria-label="أقسام بيانات الدورة" className="course-form-tabs" role="tablist">
            <button
              aria-controls="course-basic-panel"
              aria-selected={activeTab === "basic"}
              className={`course-form-tab${activeTab === "basic" ? " active" : ""}`}
              id="course-basic-tab"
              onClick={() => setActiveTab("basic")}
              role="tab"
              type="button"
            >
              البيانات الأساسية
            </button>
            <button
              aria-controls="course-details-panel"
              aria-selected={activeTab === "details"}
              className={`course-form-tab${activeTab === "details" ? " active" : ""}`}
              id="course-details-tab"
              onClick={() => setActiveTab("details")}
              role="tab"
              type="button"
            >
              المواعيد والتفاصيل
            </button>
          </div>

          {activeTab === "basic" ? (
            <div aria-labelledby="course-basic-tab" className="form-grid" id="course-basic-panel" role="tabpanel">
              <label className="form-field">
                اسم الدورة
                <input className="form-control" maxLength={150} onChange={(event) => setTitle(event.target.value)} value={title} />
              </label>
              <label className="form-field">
                التصنيف
                <select className="form-control" onChange={(event) => setCategory(event.target.value)} value={category}>
                  <option value="">اختر تصنيف الدورة</option>
                  {courseCategories.map((item) => <option key={item} value={item}>{item}</option>)}
                  {category && !courseCategories.includes(category) && (
                    <option value={category}>{category}</option>
                  )}
                </select>
              </label>
              <label className="form-field form-field-wide">
                وصف الدورة
                <textarea className="form-control" maxLength={4000} onChange={(event) => setDescription(event.target.value)} rows={3} value={description} />
              </label>
              <label className="form-field">
                السعر الكامل <span className="form-help">بالريال اليمني</span>
                <NumericFormat
                  allowNegative={false}
                  className="form-control latin-number"
                  decimalScale={2}
                  decimalSeparator="."
                  inputMode="decimal"
                  onValueChange={({ value }) => setPrice(value)}
                  suffix=" ر.ي"
                  thousandSeparator=","
                  value={price}
                />
              </label>
              <label className="form-field">
                العربون <span className="form-help">بالريال اليمني</span>
                <NumericFormat
                  allowNegative={false}
                  className="form-control latin-number"
                  decimalScale={2}
                  decimalSeparator="."
                  inputMode="decimal"
                  onValueChange={({ value }) => setDepositAmount(value)}
                  suffix=" ر.ي"
                  thousandSeparator=","
                  value={depositAmount}
                />
              </label>
              <label className="form-field">
                السعة القصوى
                <NumericFormat
                  allowNegative={false}
                  className="form-control latin-number"
                  decimalScale={0}
                  inputMode="numeric"
                  onValueChange={({ value }) => setCapacity(value)}
                  thousandSeparator=","
                  value={capacity}
                />
              </label>
              <label className="form-field form-field-wide">
                صورة الدورة
                <input
                  accept="image/jpeg,image/png,image/webp"
                  className="form-control"
                  onChange={(event) => setImage(event.target.files?.[0])}
                  type="file"
                />
                {course?.image && !image && <span className="form-help">سيبقى الغلاف الحالي ما لم تختر صورة أخرى.</span>}
              </label>
            </div>
          ) : (
            <div aria-labelledby="course-details-tab" className="form-grid" id="course-details-panel" role="tabpanel">
              <label className="form-field form-field-wide">
                الموقع
                <input className="form-control" onChange={(event) => setLocation(event.target.value)} value={location} />
              </label>
              <label className="form-field">
                بداية الدورة
                <input className="form-control latin-number" onChange={(event) => setStartDate(event.target.value)} type="datetime-local" value={startDate} />
              </label>
              <label className="form-field">
                نهاية الدورة
                <input className="form-control latin-number" onChange={(event) => setEndDate(event.target.value)} type="datetime-local" value={endDate} />
              </label>
              <div className="form-field form-field-wide">
                <span>ماذا سيتعلم الطالب؟</span>
                <CourseListEditor
                  emptyMessage="لم تتم إضافة أهداف تعليمية بعد."
                  itemLabel="الهدف التعليمي"
                  items={whatWillLearn}
                  onChange={setWhatWillLearn}
                  placeholder="مثال: إتقان أساسيات البرمجة"
                />
              </div>
              <div className="form-field form-field-wide">
                <span>مميزات الدورة</span>
                <CourseListEditor
                  emptyMessage="لم تتم إضافة مميزات بعد."
                  itemLabel="الميزة"
                  items={features}
                  onChange={setFeatures}
                  placeholder="مثال: تطبيقات ومشاريع عملية"
                />
              </div>
              <label className="form-field form-field-wide">
                <span className="flex items-center gap-2">
                  <input checked={requiresEnglishName} onChange={(event) => setRequiresEnglishName(event.target.checked)} type="checkbox" />
                  طلب الاسم الإنجليزي عند التسجيل
                </span>
              </label>
            </div>
          )}

          {error && <div className="form-error" role="alert">{error}</div>}
          <div className="form-actions">
            <button className="button button-secondary" disabled={isSaving} onClick={onClose} type="button">إلغاء</button>
            <button className="button button-primary" disabled={isSaving} type="submit">
              {isSaving ? "جارٍ الحفظ..." : course ? "حفظ التعديلات" : "إنشاء كمسودة"}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}

function CourseListEditor({
  items,
  onChange,
  itemLabel,
  placeholder,
  emptyMessage,
}: {
  items: string[];
  onChange(items: string[]): void;
  itemLabel: string;
  placeholder: string;
  emptyMessage: string;
}) {
  const [draft, setDraft] = useState("");
  const [error, setError] = useState("");

  const addItem = () => {
    const item = draft.trim();
    if (!item) return;
    if (items.some((existing) => existing.toLocaleLowerCase("ar") === item.toLocaleLowerCase("ar"))) {
      setError("هذا العنصر مضاف بالفعل.");
      return;
    }
    onChange([...items, item]);
    setDraft("");
    setError("");
  };

  return (
    <div className="course-list-editor">
      {items.length > 0 ? (
        <ul className="course-list-items">
          {items.map((item, index) => (
            <li className="course-list-item" key={`${index}-${item}`}>
              <span>{item}</span>
              <button
                aria-label={`حذف ${itemLabel}`}
                className="icon-button course-list-remove"
                onClick={() => onChange(items.filter((_, itemIndex) => itemIndex !== index))}
                type="button"
              >
                <X size={15} />
              </button>
            </li>
          ))}
        </ul>
      ) : (
        <p className="course-list-empty">{emptyMessage}</p>
      )}
      <div className="course-list-add-row">
        <input
          aria-label={`أدخل ${itemLabel}`}
          className="form-control"
          onChange={(event) => {
            setDraft(event.target.value);
            setError("");
          }}
          onKeyDown={(event) => {
            if (event.key === "Enter") {
              event.preventDefault();
              addItem();
            }
          }}
          placeholder={placeholder}
          value={draft}
        />
        <button
          className="button button-secondary button-small"
          disabled={!draft.trim()}
          onClick={addItem}
          type="button"
        >
          <Plus size={15} /> إضافة
        </button>
      </div>
      {error && <span className="form-help form-help-error" role="alert">{error}</span>}
    </div>
  );
}
