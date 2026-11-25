import { useQuery } from "@tanstack/react-query";
import {
  ArrowUpLeft,
  BookOpenCheck,
  CalendarDays,
  CircleDollarSign,
  ClipboardCheck,
  Clock3,
  UsersRound,
} from "lucide-react";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Link } from "react-router-dom";
import { dashboardApi } from "../api/services";
import { formatCurrency, formatDate, formatNumber } from "../formatters";
import {
  Currency,
  ErrorState,
  LoadingState,
  MetricCard,
  PageHeader,
  StatusBadge,
} from "../components/ui";

const monthFormatter = new Intl.DateTimeFormat("ar-YE", { month: "short" });

function monthName(year: number, month: number) {
  return monthFormatter.format(new Date(Date.UTC(year, month - 1, 15)));
}

export function DashboardPage() {
  const dashboard = useQuery({
    queryKey: ["dashboard"],
    queryFn: dashboardApi.get,
  });

  if (dashboard.isPending) return <LoadingState />;
  if (dashboard.isError) {
    return (
      <ErrorState
        message={dashboard.error.message}
        onRetry={() => void dashboard.refetch()}
      />
    );
  }

  const data = dashboard.data;
  const summary = data.summary;
  const chartData = summary.revenue.monthly.map((item) => ({
    ...item,
    monthLabel: monthName(item.year, item.month),
  }));
  return (
    <div className="page-stack">
      <PageHeader
        title={`صباح الخير، ${data.institute.name}`}
        description="إليك ملخصًا سريعًا عن أداء معهدك ونشاطه."
        action={
          <div className="date-chip">
            <CalendarDays size={16} />
            <span>
              {new Intl.DateTimeFormat("ar-YE", {
                day: "numeric",
                month: "long",
                year: "numeric",
              }).format(new Date())}
            </span>
          </div>
        }
      />

      <section className="metrics-grid" aria-label="ملخص المعهد">
        <MetricCard
          detail={`${formatNumber(summary.courses.published)} دورة منشورة`}
          icon={<BookOpenCheck size={20} />}
          label="إجمالي الدورات"
          tone="green"
          value={formatNumber(summary.courses.total)}
        />
        <MetricCard
          detail={`${formatNumber(summary.reservations.confirmedThisMonth)} مؤكدة هذا الشهر`}
          icon={<ClipboardCheck size={20} />}
          label="تسجيلات هذا الشهر"
          tone="sage"
          value={formatNumber(summary.reservations.thisMonth)}
        />
        <MetricCard
          detail="للحجوزات المؤكدة فقط"
          icon={<CircleDollarSign size={20} />}
          label="الإيرادات المعتمدة"
          tone="gold"
          value={<Currency value={summary.revenue.total} />}
        />
        <MetricCard
          detail="طلبات الدفعة الأولى"
          icon={<Clock3 size={20} />}
          label="دفعات أولى قيد المراجعة"
          tone="coral"
          value={formatNumber(summary.reservations.receiptsToReview)}
        />
      </section>

      <section className="dashboard-main-grid">
        <article className="panel revenue-panel">
          <div className="panel-heading">
            <div>
              <span className="panel-kicker">نظرة مالية</span>
              <h2>الإيرادات المعتمدة</h2>
            </div>
            <Link className="text-link" to="/reports">
              عرض التقرير <ArrowUpLeft size={16} />
            </Link>
          </div>
          <div className="chart-summary">
            <strong className="latin-number">{formatCurrency(summary.revenue.total)}</strong>
            <span><span className="chart-dot" /> آخر ٦ أشهر</span>
          </div>
          <div className="revenue-chart">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData} margin={{ top: 12, right: 4, left: 6, bottom: 0 }}>
                <defs>
                  <linearGradient id="revenueFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#176B4D" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="#176B4D" stopOpacity={0.01} />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="#F0ECE3" strokeDasharray="4 5" vertical={false} />
                <XAxis
                  axisLine={false}
                  dataKey="monthLabel"
                  tick={{ fill: "#89928C", fontSize: 12 }}
                  tickLine={false}
                  tickMargin={12}
                />
                <YAxis
                  axisLine={false}
                  tick={{ fill: "#89928C", fontSize: 11 }}
                  tickFormatter={(value: number) => formatNumber(value)}
                  tickLine={false}
                  tickMargin={8}
                  width={54}
                />
                <Tooltip
                  contentStyle={{
                    border: "1px solid #E9E4D8",
                    borderRadius: 12,
                    direction: "rtl",
                    fontFamily: "Cairo",
                  }}
                  formatter={(value) => [formatCurrency(Number(value)), "الإيراد"]}
                  labelStyle={{ color: "#26352E", fontWeight: 700 }}
                />
                <Area
                  activeDot={{ r: 5, fill: "#176B4D", stroke: "#fff", strokeWidth: 3 }}
                  dataKey="revenue"
                  fill="url(#revenueFill)"
                  stroke="#176B4D"
                  strokeWidth={3}
                  type="monotone"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </article>

        <article className="panel occupancy-panel">
          <div className="panel-heading">
            <div>
              <span className="panel-kicker">الدورات النشطة</span>
              <h2>الأعلى إشغالًا</h2>
            </div>
            <div className="panel-icon"><UsersRound size={18} /></div>
          </div>
          {data.courseOccupancy.length === 0 ? (
            <div className="compact-empty">لا توجد دورات منشورة حاليًا.</div>
          ) : (
            <div className="occupancy-list">
              {data.courseOccupancy.map((course) => {
                const percent = course.capacity > 0
                  ? Math.min(100, Math.round((course.occupied / course.capacity) * 100))
                  : 0;
                return (
                  <div className="occupancy-item" key={course.id}>
                    <div className="occupancy-title">
                      <strong>{course.title}</strong>
                      <span className="latin-number">
                        {formatNumber(course.occupied)} / {formatNumber(course.capacity)}
                      </span>
                    </div>
                    <div
                      aria-label={`${percent}% إشغال`}
                      className="progress-track"
                      role="progressbar"
                      aria-valuemax={100}
                      aria-valuemin={0}
                      aria-valuenow={percent}
                    >
                      <span style={{ width: `${percent}%` }} />
                    </div>
                    <small>{formatNumber(percent)}٪ من المقاعد</small>
                  </div>
                );
              })}
            </div>
          )}
          <Link className="panel-footer-link" to="/courses">
            استعراض الدورات <ArrowUpLeft size={16} />
          </Link>
        </article>
      </section>

      <section className="dashboard-bottom-grid">
        <article className="panel recent-panel">
          <div className="panel-heading">
            <div>
              <span className="panel-kicker">آخر النشاطات</span>
              <h2>أحدث التسجيلات</h2>
            </div>
            <Link className="text-link" to="/reservations">
              كل الحجوزات <ArrowUpLeft size={16} />
            </Link>
          </div>
          {data.recentReservations.length === 0 ? (
            <div className="compact-empty">ستظهر التسجيلات الجديدة هنا.</div>
          ) : (
            <div className="recent-list">
              {data.recentReservations.map((reservation) => (
                <div className="recent-row" key={reservation.id}>
                  <div className="recent-avatar">{reservation.studentName.slice(0, 1)}</div>
                  <div className="recent-main">
                    <strong>{reservation.studentName}</strong>
                    <span>{reservation.courseTitle || "دورة غير متاحة"}</span>
                  </div>
                  <time>{formatDate(reservation.createdAt)}</time>
                  <StatusBadge status={reservation.status} />
                </div>
              ))}
            </div>
          )}
        </article>

        <article className="panel attention-panel">
          <div className="panel-heading">
            <div>
              <span className="panel-kicker">تنبيهات المعهد</span>
              <h2>ما يستحق انتباهك</h2>
            </div>
          </div>
          <div className="attention-item attention-coral">
            <div className="attention-icon"><Clock3 size={18} /></div>
            <div>
              <strong>دفعات أولى قيد المراجعة</strong>
              <span>راجع السندات المرفوعة لاعتماد الحجز.</span>
            </div>
            <b className="latin-number">{formatNumber(summary.reservations.receiptsToReview)}</b>
          </div>
          <div className="attention-item attention-gold">
            <div className="attention-icon"><CalendarDays size={18} /></div>
            <div>
              <strong>دورات تبدأ قريبًا</strong>
              <span>خلال الأيام السبعة القادمة.</span>
            </div>
            <b className="latin-number">{formatNumber(data.alerts.coursesStartingSoon)}</b>
          </div>
          <div className="attention-item attention-green">
            <div className="attention-icon"><UsersRound size={18} /></div>
            <div>
              <strong>دورات مكتملة المقاعد</strong>
              <span>تابع السعة المتاحة في دوراتك.</span>
            </div>
            <b className="latin-number">{formatNumber(data.alerts.fullCourses)}</b>
          </div>
        </article>
      </section>

      <div className="dashboard-footnote">
        <span>الإيرادات المعروضة تشمل الحجوزات المؤكدة فقط.</span>
        <Link className="text-link" to="/reservations">مراجعة التسجيلات والدفعات</Link>
      </div>
    </div>
  );
}
