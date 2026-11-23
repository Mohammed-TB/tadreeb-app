import { useQuery } from "@tanstack/react-query";
import {
  BookOpenCheck,
  ChartNoAxesCombined,
  ClipboardList,
  LayoutDashboard,
  LogOut,
  PanelRightClose,
} from "lucide-react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { dashboardApi, instituteApi } from "../api/services";

const navigation = [
  { to: "/dashboard", label: "الرئيسية", icon: LayoutDashboard },
  { to: "/courses", label: "الدورات", icon: BookOpenCheck },
  { to: "/reservations", label: "الحجوزات", icon: ClipboardList },
  { to: "/reports", label: "التقارير", icon: ChartNoAxesCombined },
];

export function AppShell() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const instituteQuery = useQuery({
    queryKey: ["institute"],
    queryFn: instituteApi.getMine,
  });
  const dashboardQuery = useQuery({
    queryKey: ["dashboard"],
    queryFn: dashboardApi.get,
  });
  const instituteName =
    instituteQuery.data?.name ?? dashboardQuery.data?.institute.name ?? "معهدي";
  const today = new Intl.DateTimeFormat("ar-YE", {
    weekday: "long",
    day: "numeric",
    month: "long",
  }).format(new Date());

  const handleLogout = async () => {
    await logout();
    navigate("/login", { replace: true });
  };

  return (
    <div className="app-shell" dir="rtl">
      <aside className="sidebar">
        <div className="brand-lockup">
          <div className="brand-mark">
            <BookOpenCheck size={22} strokeWidth={2.2} />
          </div>
          <div className="brand-name">
            <strong>تدريب</strong>
            <span>إدارة المعهد</span>
          </div>
        </div>

        <div className="sidebar-caption">مساحة العمل</div>
        <nav className="side-nav" aria-label="القائمة الرئيسية">
          {navigation.map(({ to, label, icon: Icon }) => (
            <NavLink
              className={({ isActive }) =>
                `side-nav-link${isActive ? " active" : ""}`
              }
              key={to}
              to={to}
            >
              <Icon size={19} />
              <span>{label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-bottom">
          <div className="sidebar-institute">
            <div className="institute-avatar">{instituteName.slice(0, 1)}</div>
            <div>
              <strong>{instituteName}</strong>
              <span>حساب صاحب المعهد</span>
            </div>
          </div>
          <button className="logout-button" onClick={handleLogout}>
            <LogOut size={18} />
            <span>تسجيل الخروج</span>
          </button>
        </div>
      </aside>

      <div className="workspace">
        <header className="topbar">
          <div className="topbar-title">
            <span className="topbar-eyebrow">مرحبًا، {user?.name}</span>
            <strong>{instituteName}</strong>
          </div>
          <div className="topbar-meta">
            <span className="topbar-date">{today}</span>
            <span className="topbar-divider" />
            <span className="owner-avatar">{user?.name.slice(0, 1) ?? "ص"}</span>
            <div className="topbar-user">
              <strong>{user?.name}</strong>
              <span>صاحب المعهد</span>
            </div>
            <PanelRightClose className="topbar-window-mark" size={18} />
          </div>
        </header>
        <main className="page-content">
          <Outlet />
        </main>
        <footer className="workspace-footer">
          <span>تدريب لإدارة المعاهد</span>
          <span>جميع المبالغ بالريال اليمني · ر.ي</span>
        </footer>
      </div>
    </div>
  );
}
