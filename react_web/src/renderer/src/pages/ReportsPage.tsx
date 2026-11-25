import { useQuery } from "@tanstack/react-query";
import { ChartNoAxesCombined, CircleDollarSign, ClipboardCheck } from "lucide-react";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { dashboardApi } from "../api/services";
import { formatCurrency, formatNumber } from "../formatters";
import { ErrorState, LoadingState, MetricCard, PageHeader } from "../components/ui";

const monthFormatter = new Intl.DateTimeFormat("ar-YE", { month: "long" });

export function ReportsPage() {
  const report = useQuery({
    queryKey: ["dashboard"],
    queryFn: dashboardApi.get,
  });

  if (report.isPending) return <LoadingState />;
  if (report.isError) {
    return (
      <ErrorState message={report.error.message} onRetry={() => void report.refetch()} />
    );
  }

  const { revenue, reservations } = report.data.summary;
  const monthly = revenue.monthly.map((item) => ({
    ...item,
    label: monthFormatter.format(new Date(Date.UTC(item.year, item.month - 1, 15))),
  }));

  return (
    <div className="page-stack">
      <PageHeader
        title="التقارير"
        description="قراءة واضحة للإيرادات والتسجيلات بناءً على بيانات المعهد المتاحة."
        action={
          <div className="report-period-chip">
            <ChartNoAxesCombined size={16} />
            آخر ٦ أشهر
          </div>
        }
      />

      <section className="metrics-grid reports-metrics">
        <MetricCard
          detail="من الحجوزات المؤكدة"
          icon={<CircleDollarSign size={20} />}
          label="إجمالي الإيرادات المعتمدة"
          tone="green"
          value={formatCurrency(revenue.total)}
        />
        <MetricCard
          detail="جميع الحالات"
          icon={<ClipboardCheck size={20} />}
          label="إجمالي الحجوزات"
          tone="sage"
          value={formatNumber(reservations.total)}
        />
        <MetricCard
          detail="حجوزات تم اعتمادها"
          icon={<ClipboardCheck size={20} />}
          label="حجوزات مؤكدة هذا الشهر"
          tone="gold"
          value={formatNumber(reservations.confirmedThisMonth)}
        />
        <MetricCard
          detail="تحتاج مراجعة"
          icon={<ChartNoAxesCombined size={20} />}
          label="دفعات أولى قيد المراجعة"
          tone="coral"
          value={formatNumber(reservations.receiptsToReview)}
        />
      </section>

      <section className="panel report-chart-panel">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">ملخص مالي</span>
            <h2>الإيراد حسب الشهر</h2>
          </div>
          <span className="report-note">يُحتسب للحجوزات المؤكدة فقط</span>
        </div>
        <div className="report-chart">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={monthly} margin={{ top: 12, right: 8, left: 8, bottom: 0 }}>
              <defs>
                <linearGradient id="reportFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#176B4D" stopOpacity={0.2} />
                  <stop offset="100%" stopColor="#176B4D" stopOpacity={0.01} />
                </linearGradient>
              </defs>
              <CartesianGrid stroke="#F0ECE3" strokeDasharray="4 5" vertical={false} />
              <XAxis dataKey="label" axisLine={false} tickLine={false} tick={{ fill: "#89928C" }} />
              <YAxis
                axisLine={false}
                tickLine={false}
                tick={{ fill: "#89928C" }}
                tickFormatter={(value: number) => formatNumber(value)}
                width={58}
              />
              <Tooltip
                contentStyle={{ border: "1px solid #E9E4D8", borderRadius: 12, direction: "rtl", fontFamily: "Cairo" }}
                formatter={(value) => [formatCurrency(Number(value)), "الإيراد"]}
              />
              <Area
                dataKey="revenue"
                fill="url(#reportFill)"
                stroke="#176B4D"
                strokeWidth={3}
                type="monotone"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </section>

      <section className="panel monthly-table-panel">
        <div className="table-toolbar">
          <div>
            <h2>تفاصيل الأشهر</h2>
            <span>المبالغ بالريال اليمني.</span>
          </div>
        </div>
        <div className="table-scroll">
          <table className="data-table">
            <thead>
              <tr><th>الشهر</th><th>السنة</th><th>الإيراد المعتمد</th></tr>
            </thead>
            <tbody>
              {monthly.map((item) => (
                <tr key={`${item.year}-${item.month}`}>
                  <td>{item.label}</td>
                  <td className="latin-number">{formatNumber(item.year)}</td>
                  <td><strong className="latin-number">{formatCurrency(item.revenue)}</strong></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="report-limitation">
          يعتمد هذا التقرير على ملخص الخادم لآخر ستة أشهر. لا تتوفر حاليًا واجهة
          لاختيار نطاق زمني تاريخي مخصص.
        </p>
      </section>
    </div>
  );
}
