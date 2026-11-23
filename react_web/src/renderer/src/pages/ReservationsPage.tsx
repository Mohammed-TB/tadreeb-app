import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Check,
  FileImage,
  Search,
  UserRound,
  X,
} from "lucide-react";
import { reservationsApi } from "../api/services";
import { formatCurrency, formatDate, formatNumber, getCourseTitle } from "../formatters";
import {
  EmptyState,
  ErrorState,
  PageHeader,
  SkeletonRows,
  StatusBadge,
} from "../components/ui";
import type { Reservation } from "../types";

const statusOptions = [
  { value: "all", label: "كل الحالات" },
  { value: "paymentSubmitted", label: "قيد المراجعة" },
  { value: "pendingPayment", label: "بانتظار الدفع" },
  { value: "confirmed", label: "مؤكد" },
  { value: "rejected", label: "مرفوض" },
  { value: "cancelled", label: "ملغي" },
  { value: "expired", label: "منتهي" },
];

export function ReservationsPage() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [receiptUrl, setReceiptUrl] = useState<string | null>(null);
  const [actionError, setActionError] = useState("");
  const [receiptError, setReceiptError] = useState("");

  const reservations = useQuery({
    queryKey: ["reservations"],
    queryFn: reservationsApi.getAll,
  });
  const selected = reservations.data?.find((item) => item._id === selectedId) ?? null;

  const refreshReservationData = async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ["reservations"] }),
      queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
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
          <div className="page-count-chip">
            <UserRound size={16} />
            <span>{formatNumber(reservations.data?.length ?? 0)} تسجيل</span>
          </div>
        }
      />

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
                          <span>{formatDate(payment.createdAt)}{payment.paymentMethod ? ` · ${payment.paymentMethod}` : ""}</span>
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
    </div>
  );
}
