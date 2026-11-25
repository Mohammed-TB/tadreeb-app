import type { ReactNode } from "react";
import { AlertCircle, LoaderCircle } from "lucide-react";
import { formatCurrency } from "../formatters";

export function PageHeader({
  title,
  description,
  action,
}: {
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="page-header">
      <div>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      {action}
    </div>
  );
}

export function MetricCard({
  label,
  value,
  detail,
  icon,
  tone = "green",
}: {
  label: string;
  value: ReactNode;
  detail?: string;
  icon: ReactNode;
  tone?: "green" | "coral" | "gold" | "sage";
}) {
  return (
    <article className="metric-card">
      <div className={`metric-icon metric-icon-${tone}`}>{icon}</div>
      <div className="metric-copy">
        <span>{label}</span>
        <strong className="latin-number">{value}</strong>
        {detail && <small>{detail}</small>}
      </div>
    </article>
  );
}

const statusLabels: Record<string, string> = {
  draft: "مسودة",
  published: "منشورة",
  closed: "مغلقة",
  completed: "مكتملة",
  pendingPayment: "بانتظار الدفع",
  paymentSubmitted: "قيد المراجعة",
  confirmed: "مؤكد",
  rejected: "مرفوض",
  expired: "منتهي",
  cancelled: "ملغي",
  unpaid: "غير مدفوع",
  partial: "مدفوع جزئيًا",
  paid: "مدفوع",
  none: "لا يوجد",
  pending: "قيد المراجعة",
  approved: "معتمد",
  attended: "حضر",
  absent: "غائب",
  notMarked: "غير محدد",
};

const statusTones: Record<string, string> = {
  published: "success",
  confirmed: "success",
  paid: "success",
  approved: "success",
  attended: "success",
  paymentSubmitted: "warning",
  pendingPayment: "warning",
  pending: "warning",
  partial: "warning",
  rejected: "danger",
  cancelled: "muted",
  expired: "muted",
  draft: "muted",
  closed: "muted",
  completed: "info",
  unpaid: "muted",
  absent: "danger",
  notMarked: "muted",
  none: "muted",
};

export function StatusBadge({ status }: { status: string }) {
  return (
    <span className={`status-badge status-${statusTones[status] ?? "muted"}`}>
      {statusLabels[status] ?? status}
    </span>
  );
}

export function LoadingState({ label = "جارٍ تحميل البيانات..." }: { label?: string }) {
  return (
    <div className="state-card loading-state" role="status">
      <LoaderCircle size={22} className="spin" />
      <span>{label}</span>
    </div>
  );
}

export function ErrorState({
  message,
  onRetry,
}: {
  message: string;
  onRetry: () => void;
}) {
  return (
    <div className="state-card error-state" role="alert">
      <AlertCircle size={22} />
      <span>{message}</span>
      <button className="button button-secondary button-small" onClick={onRetry}>
        إعادة المحاولة
      </button>
    </div>
  );
}

export function SkeletonRows({ count = 5 }: { count?: number }) {
  return (
    <div className="skeleton-list" aria-label="جارٍ التحميل">
      {Array.from({ length: count }, (_, index) => (
        <div className="skeleton-row" key={index}>
          <span />
          <span />
          <span />
          <span />
        </div>
      ))}
    </div>
  );
}

export function EmptyState({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div className="empty-state">
      <div className="empty-state-mark">ت</div>
      <strong>{title}</strong>
      <span>{description}</span>
    </div>
  );
}

export function Currency({ value }: { value: number }) {
  return <span className="latin-number">{formatCurrency(value)}</span>;
}
