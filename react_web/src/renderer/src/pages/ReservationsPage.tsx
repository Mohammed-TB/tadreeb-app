import { useEffect, useMemo, useState, type FormEvent } from "react";
import { useSearchParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Banknote,
  Check,
  CirclePlus,
  CreditCard,
  FileImage,
  Search,
  UserRound,
  X,
} from "lucide-react";
import { coursesApi, instituteApi, reservationsApi } from "../api/services";
import { isValidPhone, PhoneNumberField } from "../components/PhoneNumberField";
import { formatCurrency, formatDate, formatNumber, getCourseTitle } from "../formatters";
import {
  EmptyState,
  ErrorState,
  PageHeader,
  SkeletonRows,
  StatusBadge,
} from "../components/ui";
import type { Course, InstituteSettings, Reservation } from "../types";

const statusOptions = [
  { value: "all", label: "كل الحالات" },
  { value: "paymentSubmitted", label: "قيد المراجعة" },
  { value: "pendingPayment", label: "بانتظار الدفع" },
  { value: "confirmed", label: "مؤكد" },
  { value: "rejected", label: "مرفوض" },
  { value: "cancelled", label: "ملغي" },
  { value: "expired", label: "منتهي" },
];

function getSaudiDayStart() {
  const saudiOffsetMs = 3 * 60 * 60 * 1000;
  const saudiNow = new Date(Date.now() + saudiOffsetMs);
  saudiNow.setUTCHours(0, 0, 0, 0);
  return new Date(saudiNow.getTime() - saudiOffsetMs);
}

export function ReservationsPage() {
  const queryClient = useQueryClient();
  const [searchParams, setSearchParams] = useSearchParams();
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [receiptUrl, setReceiptUrl] = useState<string | null>(null);
  const [actionError, setActionError] = useState("");
  const [receiptError, setReceiptError] = useState("");
  const [createInPersonOpen, setCreateInPersonOpen] = useState(false);
  const [notice, setNotice] = useState("");

  const reservations = useQuery({
    queryKey: ["reservations"],
    queryFn: reservationsApi.getAll,
  });
  const courses = useQuery({
    queryKey: ["courses"],
    queryFn: coursesApi.getAll,
  });
  const instituteSettings = useQuery({
    queryKey: ["institute-settings"],
    queryFn: instituteApi.getSettings,
  });
  const selected = reservations.data?.find((item) => item._id === selectedId) ?? null;

  useEffect(() => {
    const reservationId = searchParams.get("reservationId");
    if (!reservationId) return;
    if (reservations.data?.some((item) => item._id === reservationId)) {
      setSelectedId(reservationId);
      const next = new URLSearchParams(searchParams);
      next.delete("reservationId");
      setSearchParams(next, { replace: true });
    }
  }, [reservations.data, searchParams, setSearchParams]);

  const refreshReservationData = async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ["reservations"] }),
      queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
      queryClient.invalidateQueries({ queryKey: ["courses"] }),
    ]);
  };

  const approve = useMutation({
    mutationFn: reservationsApi.approve,
    onSuccess: refreshReservationData,
    onError: (error) => setActionError(error.message),
  });
  const reject = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      reservationsApi.reject(id, reason),
    onSuccess: async () => {
      setRejectionReason("");
      await refreshReservationData();
    },
    onError: (error) => setActionError(error.message),
  });
  const approveBalance = useMutation({
    mutationFn: reservationsApi.approveBalance,
    onSuccess: refreshReservationData,
    onError: (error) => setActionError(error.message),
  });
  const rejectBalance = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      reservationsApi.rejectBalance(id, reason),
    onSuccess: async () => {
      setRejectionReason("");
      await refreshReservationData();
    },
    onError: (error) => setActionError(error.message),
  });
  const receipt = useMutation({
    mutationFn: async ({
      id,
      type,
    }: {
      id: string;
      type: "reservation" | "balance" | "payment";
    }) => {
      if (type === "reservation") return reservationsApi.getReservationReceipt(id);
      if (type === "balance") return reservationsApi.getBalanceReceipt(id);
      return reservationsApi.getPaymentReceipt(id);
    },
    onSuccess: (result) => {
      setReceiptError("");
      setReceiptUrl(result.receiptUrl);
    },
    onError: (error) => setReceiptError(error.message),
  });

  const filteredReservations = useMemo(() => {
    const query = search.trim().toLocaleLowerCase("ar");
    return (reservations.data ?? []).filter((reservation) => {
      const matchesStatus = statusFilter === "all" || reservation.status === statusFilter;
      const searchable = [
        reservation.studentName,
        reservation.studentPhone,
        getCourseTitle(reservation.courseId),
      ].join(" ").toLocaleLowerCase("ar");
      return matchesStatus && (!query || searchable.includes(query));
    });
  }, [reservations.data, search, statusFilter]);

  const closeDetails = () => {
    setSelectedId(null);
    setActionError("");
    setRejectionReason("");
  };

  const submitReject = (balance = false) => {
    if (!selected || !rejectionReason.trim()) {
      setActionError("اكتب سبب الرفض قبل المتابعة.");
      return;
    }
    setActionError("");
    if (balance) {
      rejectBalance.mutate({ id: selected._id, reason: rejectionReason.trim() });
    } else {
      reject.mutate({ id: selected._id, reason: rejectionReason.trim() });
    }
  };

  const isMutating =
    approve.isPending ||
    reject.isPending ||
    approveBalance.isPending ||
    rejectBalance.isPending;

  return (
    <div className="page-stack">
      <PageHeader
        title="الحجوزات"
        description="راجع تسجيلات الطلاب ودفعاتهم، واعتمد السندات أو ارفضها مع توضيح السبب."
        action={
          <div className="header-actions">
            <div className="page-count-chip">
              <UserRound size={16} />
              <span>{formatNumber(reservations.data?.length ?? 0)} تسجيل</span>
            </div>
            <button
              className="button button-primary"
              onClick={() => {
                setActionError("");
                setNotice("");
                setCreateInPersonOpen(true);
              }}
            >
              <CirclePlus size={17} /> تسجيل حضوري
            </button>
          </div>
        }
      />

      {notice && (
        <div className="toast-message" role="status">
          <span>{notice}</span>
          <button aria-label="إغلاق الرسالة" className="icon-button" onClick={() => setNotice("")}>
            <X size={15} />
          </button>
        </div>
      )}

      <section className="panel table-panel reservations-panel">
        <div className="table-toolbar reservation-toolbar">
          <div>
            <h2>سجل الحجوزات</h2>
            <span>اختر أي تسجيل لعرض تفاصيل الدفعات وإجراءات المراجعة.</span>
          </div>
          <div className="reservation-filters">
            <label className="search-field">
              <Search size={17} />
              <input
                aria-label="ابحث عن طالب أو دورة"
                onChange={(event) => setSearch(event.target.value)}
                placeholder="اسم الطالب أو الدورة..."
                value={search}
              />
            </label>
            <select
              aria-label="تصفية حسب الحالة"
              className="select-field"
              onChange={(event) => setStatusFilter(event.target.value)}
              value={statusFilter}
            >
              {statusOptions.map((option) => (
                <option key={option.value} value={option.value}>{option.label}</option>
              ))}
            </select>
          </div>
        </div>

        {reservations.isPending ? (
          <SkeletonRows />
        ) : reservations.isError ? (
          <ErrorState
            message={reservations.error.message}
            onRetry={() => void reservations.refetch()}
          />
        ) : filteredReservations.length === 0 ? (
          <EmptyState
            description={search || statusFilter !== "all" ? "غيّر كلمات البحث أو الفلتر." : "ستظهر تسجيلات الطلاب هنا."}
            title={search || statusFilter !== "all" ? "لا توجد نتائج" : "لا توجد حجوزات"}
          />
        ) : (
          <div className="table-scroll">
            <table className="data-table reservations-table">
              <thead>
                <tr>
                  <th>الطالب</th>
                  <th>الدورة</th>
                  <th>تاريخ التسجيل</th>
                  <th>المدفوع / الإجمالي</th>
                  <th>الحالة</th>
                  <th><span className="visually-hidden">التفاصيل</span></th>
                </tr>
              </thead>
              <tbody>
                {filteredReservations.map((reservation) => (
                  <tr
                    className={selectedId === reservation._id ? "selected-row" : ""}
                    key={reservation._id}
                    onClick={() => {
                      setSelectedId(reservation._id);
                      setActionError("");
                    }}
                    tabIndex={0}
                    onKeyDown={(event) => {
                      if (event.key === "Enter") setSelectedId(reservation._id);
                    }}
                  >
                    <td>
                      <div className="student-cell">
                        <div className="student-avatar">{reservation.studentName.slice(0, 1)}</div>
                        <div>
                          <strong>{reservation.studentName}</strong>
                          <span className="latin-number">{reservation.studentPhone}</span>
                        </div>
                      </div>
                    </td>
                    <td>{getCourseTitle(reservation.courseId)}</td>
                    <td>{formatDate(reservation.createdAt)}</td>
                    <td>
                      <strong className="latin-number">{formatCurrency(reservation.amountPaid)}</strong>
                      <small className="table-subtext">
                        من {formatCurrency(reservation.totalAmount)}
                      </small>
                    </td>
                    <td><StatusBadge status={reservation.status} /></td>
                    <td><span className="row-chevron">‹</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <div className="table-foot">
          <span>
            عرض {formatNumber(filteredReservations.length)} من {formatNumber(reservations.data?.length ?? 0)} تسجيل
          </span>
          <span>القائمة الحالية تُحمّل من واجهة المعهد المتاحة.</span>
        </div>
      </section>

      {selected && (
        <div className="drawer-backdrop" onMouseDown={(event) => {
          if (event.target === event.currentTarget) closeDetails();
        }}>
          <aside aria-label="تفاصيل الحجز" aria-modal="true" className="reservation-drawer" role="dialog">
            <div className="drawer-header">
              <div>
                <span className="panel-kicker">تفاصيل التسجيل</span>
                <h2>{selected.studentName}</h2>
              </div>
              <button aria-label="إغلاق" className="icon-button" onClick={closeDetails}>
                <X size={20} />
              </button>
            </div>

            <div className="drawer-body">
              <div className="drawer-summary">
                <div className="drawer-summary-course">{getCourseTitle(selected.courseId)}</div>
                <StatusBadge status={selected.status} />
                <div className="drawer-summary-grid">
                  <div><span>رقم التواصل</span><strong className="latin-number">{selected.studentPhone}</strong></div>
                  <div><span>تاريخ التسجيل</span><strong>{formatDate(selected.createdAt)}</strong></div>
                  <div><span>طريقة التسجيل</span><strong>{selected.bookingType === "inPerson" ? "حضوري" : "إلكتروني"}</strong></div>
                  <div><span>حالة الرسوم</span><strong><StatusBadge status={selected.paymentStatus} /></strong></div>
                </div>
              </div>

              <section className="drawer-section">
                <div className="drawer-section-title">
                  <h3>ملخص الرسوم</h3>
                  <span>{selected.payments.length} دفعة</span>
                </div>
                <div className="fee-summary">
                  <div><span>إجمالي الرسوم</span><strong className="latin-number">{formatCurrency(selected.totalAmount)}</strong></div>
                  <div><span>المعتمد والمدفوع</span><strong className="latin-number fee-paid">{formatCurrency(selected.amountPaid)}</strong></div>
                  <div><span>المتبقي</span><strong className="latin-number">{formatCurrency(Math.max(0, selected.totalAmount - selected.amountPaid))}</strong></div>
                </div>
              </section>

              <section className="drawer-section">
                <div className="drawer-section-title">
                  <h3>سجل الدفعات</h3>
                </div>
                {selected.payments.length === 0 ? (
                  <p className="drawer-empty">لا توجد دفعات مسجلة لهذا الحجز.</p>
                ) : (
                  <div className="payment-history">
                    {selected.payments.map((payment) => (
                      <div className="payment-history-row" key={payment._id}>
                        <div className="payment-history-mark"><span /></div>
                        <div className="payment-history-copy">
                          <strong className="latin-number">{formatCurrency(payment.amount)}</strong>
                          <span>{formatDate(payment.createdAt)}{payment.method ? ` · ${payment.method}` : ""}</span>
                          {payment.status && <StatusBadge status={payment.status} />}
                        </div>
                        {payment.hasReceipt && (
                          <button
                            className="receipt-button"
                            disabled={receipt.isPending}
                            onClick={() => receipt.mutate({ id: payment._id, type: "payment" })}
                          >
                            <FileImage size={16} /> السند
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                )}
                {selected.hasReceipt && (
                  <button
                    className="receipt-wide-button"
                    disabled={receipt.isPending}
                    onClick={() => receipt.mutate({ id: selected._id, type: "reservation" })}
                  >
                    <FileImage size={16} /> عرض سند الدفعة الأولى
                  </button>
                )}
                {selected.hasBalanceReceipt && (
                  <button
                    className="receipt-wide-button"
                    disabled={receipt.isPending}
                    onClick={() => receipt.mutate({ id: selected._id, type: "balance" })}
                  >
                    <FileImage size={16} /> عرض سند دفعة الرصيد
                  </button>
                )}
                {receiptError && <p className="inline-error" role="alert">{receiptError}</p>}
              </section>

              {(selected.rejectionReason || selected.balancePaymentRejectionReason) && (
                <div className="rejection-note">
                  <strong>ملاحظة الرفض</strong>
                  <span>{selected.balancePaymentRejectionReason || selected.rejectionReason}</span>
                </div>
              )}

              {selected.status === "paymentSubmitted" && (
                <section className="review-actions">
                  <h3>مراجعة الحجز</h3>
                  <p>اعتماد الحجز يحدّث الرصيد وفقًا للسند المرفوع.</p>
                  <div className="review-buttons">
                    <button
                      className="button button-primary"
                      disabled={isMutating}
                      onClick={() => {
                        setActionError("");
                        approve.mutate(selected._id);
                      }}
                    >
                      <Check size={17} /> اعتماد الدفعة والحجز
                    </button>
                  </div>
                  <label className="reason-label" htmlFor="reject-reason">سبب الرفض</label>
                  <textarea
                    id="reject-reason"
                    onChange={(event) => setRejectionReason(event.target.value)}
                    placeholder="اكتب ملاحظة توضح سبب رفض السند..."
                    rows={2}
                    value={rejectionReason}
                  />
                  <button
                    className="button button-danger"
                    disabled={isMutating || !rejectionReason.trim()}
                    onClick={() => submitReject(false)}
                  >
                    <X size={17} /> رفض السند
                  </button>
                </section>
              )}

              {selected.balancePaymentStatus === "pending" && (
                <section className="review-actions">
                  <h3>مراجعة دفعة الرصيد</h3>
                  <p>
                    المبلغ المرسل: <strong className="latin-number">{formatCurrency(selected.balancePaymentAmount)}</strong>
                  </p>
                  <div className="review-buttons">
                    <button
                      className="button button-primary"
                      disabled={isMutating}
                      onClick={() => {
                        setActionError("");
                        approveBalance.mutate(selected._id);
                      }}
                    >
                      <Check size={17} /> اعتماد دفعة الرصيد
                    </button>
                  </div>
                  <label className="reason-label" htmlFor="balance-reject-reason">سبب الرفض</label>
                  <textarea
                    id="balance-reject-reason"
                    onChange={(event) => setRejectionReason(event.target.value)}
                    placeholder="اكتب ملاحظة توضح سبب رفض الدفعة..."
                    rows={2}
                    value={rejectionReason}
                  />
                  <button
                    className="button button-danger"
                    disabled={isMutating || !rejectionReason.trim()}
                    onClick={() => submitReject(true)}
                  >
                    <X size={17} /> رفض دفعة الرصيد
                  </button>
                </section>
              )}

              {selected.bookingType === "inPerson" &&
                selected.status === "rejected" &&
                selected.receiptResubmissionDeadline &&
                new Date(selected.receiptResubmissionDeadline) > new Date() &&
                selected.payments.some(
                  (payment) =>
                    payment.status === "rejected" &&
                    (payment.method === "bankTransfer" || payment.method === "bank_transfer"),
                ) && (
                  <ResubmitReceiptForm
                    disabled={isMutating}
                    deadline={selected.receiptResubmissionDeadline}
                    reservation={selected}
                    onError={setActionError}
                    onSuccess={async () => {
                      await refreshReservationData();
                      setActionError("");
                      setNotice("تم رفع السند البديل، وهو الآن قيد المراجعة.");
                    }}
                  />
                )}

              {selected.status === "confirmed" &&
                selected.paymentStatus === "partial" &&
                selected.balancePaymentStatus !== "pending" && (
                  instituteSettings.isPending ? (
                    <section className="review-actions"><SkeletonRows count={1} /></section>
                  ) : instituteSettings.isError ? (
                    <section className="review-actions">
                      <ErrorState
                        message={instituteSettings.error.message}
                        onRetry={() => void instituteSettings.refetch()}
                      />
                    </section>
                  ) : (
                    <BalancePaymentForm
                      reservation={selected}
                      settings={{
                        ...instituteSettings.data,
                        balancePaymentPolicy:
                          selected.balancePaymentPolicy ??
                          instituteSettings.data.balancePaymentPolicy,
                        minimumInstallmentAmount:
                          selected.minimumInstallmentAmount ??
                          instituteSettings.data.minimumInstallmentAmount,
                      }}
                      onError={setActionError}
                      onSuccess={async (message) => {
                        await refreshReservationData();
                        setActionError("");
                        setNotice(message);
                      }}
                    />
                  )
                )}

              {actionError && <p className="inline-error" role="alert">{actionError}</p>}
            </div>
          </aside>
        </div>
      )}

      {receiptUrl && (
        <div className="receipt-modal-backdrop" onMouseDown={(event) => {
          if (event.target === event.currentTarget) setReceiptUrl(null);
        }}>
          <section aria-label="معاينة سند الدفع" aria-modal="true" className="receipt-modal" role="dialog">
            <div className="receipt-modal-header">
              <div>
                <span className="panel-kicker">مستند الدفع</span>
                <h2>معاينة السند</h2>
              </div>
              <button aria-label="إغلاق" className="icon-button" onClick={() => setReceiptUrl(null)}>
                <X size={20} />
              </button>
            </div>
            <img alt="سند الدفع المرفوع" src={receiptUrl} />
          </section>
        </div>
      )}

      {createInPersonOpen && (
        <CreateInPersonDialog
          courses={courses.data ?? []}
          coursesError={courses.isError ? courses.error.message : ""}
          isLoadingCourses={courses.isPending}
          onClose={() => setCreateInPersonOpen(false)}
          onCreated={async (studentName) => {
            await refreshReservationData();
            setCreateInPersonOpen(false);
            setNotice(`تم تسجيل ${studentName} حضوريًا.`);
          }}
          onRetryCourses={() => void courses.refetch()}
        />
      )}
    </div>
  );
}

function CreateInPersonDialog({
  courses,
  coursesError,
  isLoadingCourses,
  onClose,
  onCreated,
  onRetryCourses,
}: {
  courses: Course[];
  coursesError: string;
  isLoadingCourses: boolean;
  onClose(): void;
  onCreated(studentName: string): Promise<void>;
  onRetryCourses(): void;
}) {
  const [courseId, setCourseId] = useState("");
  const [studentName, setStudentName] = useState("");
  const [studentEnglishName, setStudentEnglishName] = useState("");
  const [studentPhone, setStudentPhone] = useState("");
  const [paymentAmount, setPaymentAmount] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<"cash" | "bankTransfer">("cash");
  const [receiptFile, setReceiptFile] = useState<File>();
  const [error, setError] = useState("");
  const [lookupMessage, setLookupMessage] = useState("");
  const [lookupError, setLookupError] = useState("");
  const lookup = useMutation({
    mutationFn: reservationsApi.lookupStudent,
    onSuccess: (name) => {
      setLookupError("");
      if (name) {
        setStudentName(name);
        setLookupMessage("عُثر على اسم سابق لهذا الرقم وتم تعبئته.");
      } else {
        setLookupMessage("لم يُعثر على اسم سابق؛ أدخل الاسم الرباعي يدويًا.");
      }
    },
    onError: (reason) => {
      setLookupMessage("");
      setLookupError(reason.message);
    },
  });
  const create = useMutation({
    mutationFn: reservationsApi.createInPerson,
    onSuccess: async () => onCreated(studentName.trim()),
    onError: (reason) => setError(reason.message),
  });

  const courseOptions = courses.filter((course) => {
    return (
      course.status === "published" &&
      new Date(course.startDate) > new Date() &&
      new Date(course.endDate) >= getSaudiDayStart()
    );
  });
  const availableCourses = courseOptions.filter((course) => {
    const seatsTaken = (course.enrolledCount ?? 0) + (course.reservedCount ?? 0);
    return seatsTaken < course.capacity;
  });
  const chosenCourse = availableCourses.find((course) => course._id === courseId);

  const lookupName = () => {
    const normalizedPhone = studentPhone.trim();
    if (!isValidPhone(normalizedPhone)) {
      setLookupError("أدخل رقم هاتف صحيحًا أولًا، واختر الدولة من القائمة.");
      return;
    }
    setLookupMessage("");
    setLookupError("");
    lookup.mutate(normalizedPhone);
  };

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    if (!chosenCourse) {
      setError("اختر دورة منشورة لديها مقاعد متاحة.");
      return;
    }
    if (studentName.trim().split(/\s+/).length < 4) {
      setError("أدخل الاسم الرباعي للطالب.");
      return;
    }
    if (!isValidPhone(studentPhone)) {
      setError("أدخل رقم هاتف صحيحًا واختر الدولة من القائمة.");
      return;
    }
    const amount = Number(paymentAmount);
    if (!Number.isFinite(amount) || amount < chosenCourse.depositAmount || amount > chosenCourse.price) {
      setError(`يجب أن تكون الدفعة بين العربون ${formatCurrency(chosenCourse.depositAmount)} والسعر الكامل ${formatCurrency(chosenCourse.price)}.`);
      return;
    }
    if (paymentMethod === "bankTransfer" && !receiptFile) {
      setError("أرفق صورة سند التحويل البنكي.");
      return;
    }
    if (receiptFile && receiptFile.size > 5 * 1024 * 1024) {
      setError("حجم صورة السند يجب ألا يتجاوز 5 ميجابايت.");
      return;
    }
    if (receiptFile && !["image/jpeg", "image/png", "image/webp"].includes(receiptFile.type)) {
      setError("صيغة السند المدعومة هي JPG أو PNG أو WEBP.");
      return;
    }
    if (chosenCourse.requiresEnglishName && !studentEnglishName.trim()) {
      setError("هذه الدورة تتطلب الاسم باللغة الإنجليزية.");
      return;
    }
    create.mutate({
      courseId: chosenCourse._id,
      studentName: studentName.trim(),
      studentPhone: studentPhone.trim(),
      studentEnglishName: studentEnglishName.trim() || undefined,
      paymentAmount: amount,
      paymentMethod,
      receipt: paymentMethod === "bankTransfer" ? receiptFile : undefined,
    });
  };

  return (
    <div className="form-dialog-backdrop" onMouseDown={(event) => {
      if (event.target === event.currentTarget && !create.isPending) onClose();
    }}>
      <section aria-label="تسجيل طالب حضوري" aria-modal="true" className="form-dialog compact-form-dialog" role="dialog">
        <div className="form-dialog-header">
          <div>
            <span className="panel-kicker">إضافة تسجيل جديد</span>
            <h2>تسجيل طالب حضوري</h2>
          </div>
          <button aria-label="إغلاق" className="icon-button" disabled={create.isPending} onClick={onClose}>
            <X size={20} />
          </button>
        </div>
        <form className="form-dialog-body" onSubmit={submit}>
          <div className="form-grid">
            <label className="form-field form-field-wide">
              الدورة
              <select
                className="form-control"
                disabled={isLoadingCourses || Boolean(coursesError)}
                onChange={(event) => {
                  setCourseId(event.target.value);
                  const picked = availableCourses.find((course) => course._id === event.target.value);
                  setPaymentAmount(picked ? String(picked.depositAmount) : "");
                }}
                required
                value={courseId}
              >
                <option value="">
                  {isLoadingCourses
                    ? "جارٍ تحميل الدورات..."
                    : coursesError
                      ? "تعذر تحميل الدورات"
                      : courseOptions.length
                        ? "اختر دورة منشورة"
                        : "لا توجد دورات قادمة"}
                </option>
                {courseOptions.map((course) => {
                  const seatsTaken = (course.enrolledCount ?? 0) + (course.reservedCount ?? 0);
                  const remainingSeats = Math.max(0, course.capacity - seatsTaken);
                  const isFull = remainingSeats === 0;
                  return (
                    <option disabled={isFull} key={course._id} value={course._id}>
                      {course.title} · {formatCurrency(course.price)} · {isFull ? "مكتملة" : `متاح ${formatNumber(remainingSeats)}`}
                    </option>
                  );
                })}
              </select>
              {coursesError ? (
                <span className="form-help form-help-error" role="alert">
                  تعذر تحميل الدورات: {coursesError}
                  <button className="text-button" onClick={onRetryCourses} type="button">إعادة المحاولة</button>
                </span>
              ) : !isLoadingCourses && availableCourses.length === 0 ? (
                <span className="form-help">
                  {courseOptions.length
                    ? "الدورات القادمة مكتملة حاليًا."
                    : "لا توجد دورة منشورة قادمة متاحة للتسجيل."}
                </span>
              ) : null}
            </label>

            <label className="form-field form-field-wide">
              رقم الهاتف
              <div className="lookup-field">
                <PhoneNumberField
                  label="رقم هاتف الطالب"
                  onChange={(value) => {
                    setStudentPhone(value);
                    setLookupMessage("");
                    setLookupError("");
                  }}
                  value={studentPhone}
                />
                <button
                  className="button button-secondary button-small"
                  disabled={lookup.isPending}
                  onClick={lookupName}
                  type="button"
                >
                  <Search size={15} /> {lookup.isPending ? "بحث..." : "بحث"}
                </button>
              </div>
              {lookupMessage && <span className="form-help form-help-success">{lookupMessage}</span>}
              {lookupError && <span className="form-help form-help-error" role="alert">{lookupError}</span>}
            </label>

            <label className="form-field form-field-wide">
              الاسم الرباعي
              <input autoComplete="name" className="form-control" onChange={(event) => setStudentName(event.target.value)} required value={studentName} />
            </label>

            {chosenCourse?.requiresEnglishName && (
              <label className="form-field form-field-wide">
                الاسم باللغة الإنجليزية
                <input className="form-control latin-number" onChange={(event) => setStudentEnglishName(event.target.value)} required value={studentEnglishName} />
              </label>
            )}

            <label className="form-field">
              مبلغ الدفعة <span className="form-help">العربون {formatCurrency(chosenCourse?.depositAmount ?? 0)}</span>
              <input
                className="form-control latin-number"
                max={chosenCourse?.price}
                min={chosenCourse?.depositAmount}
                onChange={(event) => setPaymentAmount(event.target.value)}
                required
                step="0.01"
                type="number"
                value={paymentAmount}
              />
            </label>
            <label className="form-field">
              طريقة الدفع
              <select
                className="form-control"
                onChange={(event) => {
                  setPaymentMethod(event.target.value === "bankTransfer" ? "bankTransfer" : "cash");
                  setReceiptFile(undefined);
                }}
                value={paymentMethod}
              >
                <option value="cash">نقدًا</option>
                <option value="bankTransfer">تحويل بنكي</option>
              </select>
            </label>

            {paymentMethod === "bankTransfer" && (
              <label className="form-field form-field-wide">
                صورة سند التحويل
                <input
                  accept="image/jpeg,image/png,image/webp"
                  className="form-control"
                  onChange={(event) => setReceiptFile(event.target.files?.[0])}
                  required
                  type="file"
                />
                <span className="form-help">التحويل يبقى قيد المراجعة ولا يُحتسب ضمن المدفوع حتى الاعتماد.</span>
              </label>
            )}
          </div>
          {error && <div className="form-error" role="alert">{error}</div>}
          <div className="form-actions">
            <button className="button button-secondary" disabled={create.isPending} onClick={onClose} type="button">إلغاء</button>
            <button className="button button-primary" disabled={create.isPending || availableCourses.length === 0} type="submit">
              <UserRound size={16} /> {create.isPending ? "جارٍ التسجيل..." : "تأكيد التسجيل"}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}

function ResubmitReceiptForm({
  reservation,
  deadline,
  disabled,
  onError,
  onSuccess,
}: {
  reservation: Reservation;
  deadline: string;
  disabled: boolean;
  onError(message: string): void;
  onSuccess(): Promise<void>;
}) {
  const [file, setFile] = useState<File>();
  const [error, setError] = useState("");
  const resubmit = useMutation({
    mutationFn: (receipt: File) =>
      reservationsApi.resubmitInitialReceipt(reservation._id, receipt),
    onSuccess: onSuccess,
    onError: (reason) => onError(reason.message),
  });

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    if (!file) {
      setError("اختر صورة السند البديل.");
      return;
    }
    if (file.size > 5 * 1024 * 1024 || !["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
      setError("اختر صورة JPG أو PNG أو WEBP لا يتجاوز حجمها 5 ميجابايت.");
      return;
    }
    onError("");
    resubmit.mutate(file);
  };

  return (
    <section className="review-actions resubmit-actions">
      <h3>إعادة رفع سند الدفعة الأولى</h3>
      <p>المهلة متاحة حتى {new Date(deadline).toLocaleString("ar-YE")}، وسيُنشأ سجل دفعة جديد للمراجعة.</p>
      <form className="inline-payment-form" onSubmit={submit}>
        <label className="form-field">
          صورة السند البديل
          <input accept="image/jpeg,image/png,image/webp" className="form-control" onChange={(event) => setFile(event.target.files?.[0])} required type="file" />
        </label>
        {error && <p className="form-help form-help-error" role="alert">{error}</p>}
        <button className="button button-primary" disabled={disabled || resubmit.isPending} type="submit">
          <FileImage size={16} /> {resubmit.isPending ? "جارٍ الرفع..." : "إرسال للمراجعة"}
        </button>
      </form>
    </section>
  );
}

function BalancePaymentForm({
  reservation,
  settings,
  onError,
  onSuccess,
}: {
  reservation: Reservation;
  settings: InstituteSettings;
  onError(message: string): void;
  onSuccess(message: string): Promise<void>;
}) {
  const remaining = Math.max(0, reservation.totalAmount - reservation.amountPaid);
  const [amount, setAmount] = useState(String(remaining));
  const [method, setMethod] = useState<"cash" | "bankTransfer">("cash");
  const [receiptFile, setReceiptFile] = useState<File>();
  const [error, setError] = useState("");
  const payment = useMutation({
    mutationFn: (submission:
      | { amount: number; method: "cash" }
      | { amount: number; method: "bankTransfer"; receipt: File }) => {
      if (submission.method === "cash") {
        return reservationsApi.recordCashBalance(reservation._id, submission.amount);
      }
      return reservationsApi.recordTransferBalance(
        reservation._id,
        submission.amount,
        submission.receipt,
      );
    },
    onSuccess: async () => {
      await onSuccess(method === "cash" ? "تم تسجيل الدفعة النقدية واعتمادها." : "تم تسجيل التحويل، وهو الآن قيد المراجعة ولا يدخل في المدفوع حتى اعتماده.");
    },
    onError: (reason) => onError(reason.message),
  });

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    const numericAmount = Number(amount);
    if (!Number.isFinite(numericAmount) || numericAmount <= 0 || numericAmount > remaining) {
      setError(`أدخل مبلغًا أكبر من صفر ولا يتجاوز المتبقي ${formatCurrency(remaining)}.`);
      return;
    }
    if (settings.balancePaymentPolicy === "fullRemainder" && numericAmount !== remaining) {
      setError(`سياسة المعهد تتطلب دفع كامل المتبقي: ${formatCurrency(remaining)}.`);
      return;
    }
    if (
      settings.balancePaymentPolicy === "installments" &&
      numericAmount < settings.minimumInstallmentAmount &&
      numericAmount !== remaining
    ) {
      setError(`الحد الأدنى للقسط ${formatCurrency(settings.minimumInstallmentAmount)}، ويُسمح بأقل منه فقط لإقفال كامل المتبقي.`);
      return;
    }
    if (method === "bankTransfer" && !receiptFile) {
      setError("أرفق صورة سند التحويل.");
      return;
    }
    if (receiptFile && (receiptFile.size > 5 * 1024 * 1024 || !["image/jpeg", "image/png", "image/webp"].includes(receiptFile.type))) {
      setError("اختر صورة JPG أو PNG أو WEBP لا يتجاوز حجمها 5 ميجابايت.");
      return;
    }
    onError("");
    if (method === "cash") {
      payment.mutate({ amount: numericAmount, method: "cash" });
    } else if (receiptFile) {
      payment.mutate({
        amount: numericAmount,
        method: "bankTransfer",
        receipt: receiptFile,
      });
    }
  };

  return (
    <section className="review-actions balance-payment-actions">
      <h3>تسجيل دفعة رصيد</h3>
      <p>
        المتبقي <strong className="latin-number">{formatCurrency(remaining)}</strong>
        {" · "}
        {settings.balancePaymentPolicy === "fullRemainder"
          ? "السياسة: كامل المتبقي"
          : `الحد الأدنى للقسط ${formatCurrency(settings.minimumInstallmentAmount)}`}
      </p>
      <form className="inline-payment-form" onSubmit={submit}>
        <label className="form-field">
          مبلغ الدفعة
          <input
            className="form-control latin-number"
            max={remaining}
            min="0.01"
            onChange={(event) => setAmount(event.target.value)}
            required
            step="0.01"
            type="number"
            value={amount}
          />
        </label>
        <label className="form-field">
          طريقة الدفع
          <select
            className="form-control"
            onChange={(event) => {
              setMethod(event.target.value === "bankTransfer" ? "bankTransfer" : "cash");
              setReceiptFile(undefined);
            }}
            value={method}
          >
            <option value="cash">نقدًا</option>
            <option value="bankTransfer">تحويل بنكي</option>
          </select>
        </label>
        {method === "bankTransfer" && (
          <label className="form-field form-field-wide">
            صورة سند التحويل
            <input accept="image/jpeg,image/png,image/webp" className="form-control" onChange={(event) => setReceiptFile(event.target.files?.[0])} required type="file" />
          </label>
        )}
        {error && <p className="form-help form-help-error" role="alert">{error}</p>}
        <div className="payment-submit-row">
          <span className="form-help">
            {method === "cash" ? "الدفع النقدي يُعتمد فورًا." : "التحويل يبقى قيد المراجعة."}
          </span>
          <button className="button button-primary" disabled={payment.isPending} type="submit">
            {method === "cash" ? <Banknote size={16} /> : <CreditCard size={16} />}
            {payment.isPending ? "جارٍ التسجيل..." : "تسجيل الدفعة"}
          </button>
        </div>
      </form>
    </section>
  );
}
