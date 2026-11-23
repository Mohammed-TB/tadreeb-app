import { lazy, Suspense } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { AlertTriangle, LoaderCircle, RotateCw } from "lucide-react";
import { Navigate, Outlet, Route, Routes } from "react-router-dom";
import { useAuth } from "./auth/AuthContext";
import { AppShell } from "./components/layout";
import { LoginPage } from "./pages/LoginPage";

const DashboardPage = lazy(() =>
  import("./pages/DashboardPage").then((module) => ({
    default: module.DashboardPage,
  })),
);
const CoursesPage = lazy(() =>
  import("./pages/CoursesPage").then((module) => ({
    default: module.CoursesPage,
  })),
);
const ReportsPage = lazy(() =>
  import("./pages/ReportsPage").then((module) => ({
    default: module.ReportsPage,
  })),
);
const ReservationsPage = lazy(() =>
  import("./pages/ReservationsPage").then((module) => ({
    default: module.ReservationsPage,
  })),
);

function SessionLoading() {
  return (
    <main className="boot-screen" dir="rtl">
      <div className="boot-mark">ت</div>
      <LoaderCircle className="spin" size={22} />
      <span>جارٍ تجهيز مساحة العمل...</span>
    </main>
  );
}

function SessionRecovery() {
  const { error, logout, restoreSession } = useAuth();
  const queryClient = useQueryClient();

  const retry = async () => {
    await queryClient.invalidateQueries();
    await restoreSession();
  };

  return (
    <main className="boot-screen" dir="rtl">
      <div className="recovery-card">
        <div className="recovery-icon"><AlertTriangle size={24} /></div>
        <h1>تعذر استعادة الجلسة</h1>
        <p>{error ?? "تحقق من اتصال الخادم ثم حاول مجددًا."}</p>
        <div className="recovery-actions">
          <button className="button button-primary" onClick={() => void retry()}>
            <RotateCw size={17} />
            إعادة المحاولة
          </button>
          <button className="button button-secondary" onClick={() => void logout()}>
            تسجيل الخروج
          </button>
        </div>
      </div>
    </main>
  );
}

function ProtectedRoutes() {
  const { status } = useAuth();
  if (status === "loading") return <SessionLoading />;
  if (status === "unavailable") return <SessionRecovery />;
  if (status !== "authenticated") return <Navigate to="/login" replace />;
  return <Outlet />;
}

export function App() {
  const { status } = useAuth();
  if (status === "loading") return <SessionLoading />;

  return (
    <Suspense fallback={<SessionLoading />}>
      <Routes>
        <Route
          path="/login"
          element={status === "authenticated" ? <Navigate to="/dashboard" replace /> : <LoginPage />}
        />
        <Route element={<ProtectedRoutes />}>
          <Route element={<AppShell />}>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/courses" element={<CoursesPage />} />
            <Route path="/reservations" element={<ReservationsPage />} />
            <Route path="/reports" element={<ReportsPage />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to={status === "authenticated" ? "/dashboard" : "/login"} replace />} />
      </Routes>
    </Suspense>
  );
}
