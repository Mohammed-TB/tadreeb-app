import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import {
  Bell,
  BookOpenCheck,
  ChartNoAxesCombined,
  ClipboardList,
  LayoutDashboard,
  LogOut,
  PanelRightClose,
  Settings2,
} from "lucide-react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { dashboardApi, instituteApi, notificationsApi } from "../api/services";

const navigation = [
  { to: "/dashboard", label: "الرئيسية", icon: LayoutDashboard },
  { to: "/courses", label: "الدورات", icon: BookOpenCheck },
  { to: "/reservations", label: "الحجوزات", icon: ClipboardList },
  { to: "/reports", label: "التقارير", icon: ChartNoAxesCombined },
  { to: "/settings", label: "الإعدادات", icon: Settings2 },
];

export function AppShell() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const notificationsQuery = useQuery({
    queryKey: ["notifications"],
    queryFn: notificationsApi.getAll,
    refetchInterval: 30_000,
  });
  const markRead = useMutation({
    mutationFn: notificationsApi.markRead,
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["notifications"] }),
  });
  const markAllRead = useMutation({
    mutationFn: notificationsApi.markAllRead,
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["notifications"] }),
  });
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
            <div className="notification-menu">
              <button
                type="button"
                className="icon-button notification-trigger"
                aria-label="الإشعارات"
                onClick={() => setNotificationsOpen((open) => !open)}
              >
                <Bell size={19} />
                {(notificationsQuery.data?.unreadCount ?? 0) > 0 && (
                  <span className="notification-count">
                    {(notificationsQuery.data?.unreadCount ?? 0) > 99
                      ? "99+"
                      : notificationsQuery.data?.unreadCount}
                  </span>
                )}
              </button>
              {notificationsOpen && (
                <div className="notification-popover">
                  <div className="notification-popover-header">
                    <strong>الإشعارات</strong>
                    <button
                      type="button"
                      className="text-button"
                      onClick={() => markAllRead.mutate()}
                    >
                      قراءة الكل
                    </button>
                  </div>
                  {(notificationsQuery.data?.data ?? []).length === 0 ? (
                    <div className="notification-empty">
                      لا توجد إشعارات
                    </div>
                  ) : (
                    <div className="notification-list">
                      {notificationsQuery.data?.data.map((notification) => (
                        <button
                          type="button"
                          className={`notification-item${notification.isRead ? "" : " unread"}`}
                          key={notification.id}
                          onClick={() => {
                            markRead.mutate(notification.id);
                            setNotificationsOpen(false);
                            if (notification.entityType === "reservation") {
                              navigate(`/reservations?reservationId=${notification.entityId}`);
                            } else if (notification.entityType === "course") {
                              navigate(`/courses?courseId=${notification.entityId}`);
                            }
                          }}
                        >
                          <strong className="notification-item-title">
                            {notification.title}
                          </strong>
                          <span className="notification-item-body">
                            {notification.body}
                          </span>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>
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
