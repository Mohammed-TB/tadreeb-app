import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { ApiError } from "../api/client";
import { authApi } from "../api/services";
import type { AuthUser } from "../types";

type AuthStatus = "loading" | "anonymous" | "authenticated" | "unavailable";

interface AuthContextValue {
  status: AuthStatus;
  user: AuthUser | null;
  error: string | null;
  login(email: string, password: string): Promise<void>;
  logout(): Promise<void>;
  restoreSession(): Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function ensureInstituteOwner(user: AuthUser) {
  if (user.role !== "instituteOwner" || user.status !== "active") {
    throw new ApiError("هذا التطبيق مخصص لحسابات أصحاب المعاهد النشطة.", 403);
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<AuthStatus>("loading");
  const [user, setUser] = useState<AuthUser | null>(null);
  const [error, setError] = useState<string | null>(null);

  const restoreSession = useCallback(async () => {
    setStatus("loading");
    setError(null);
    try {
      const token = await window.desktop.getAccessToken();
      if (!token) {
        setUser(null);
        setStatus("anonymous");
        return;
      }

      const currentUser = await authApi.currentUser();
      ensureInstituteOwner(currentUser);
      setUser(currentUser);
      setStatus("authenticated");
    } catch (restoreError) {
      if (
        restoreError instanceof ApiError &&
        (restoreError.status === 401 || restoreError.status === 403)
      ) {
        await window.desktop.clearAccessToken();
        setUser(null);
        setStatus("anonymous");
        setError(restoreError.message);
        return;
      }

      setError(
        restoreError instanceof Error
          ? restoreError.message
          : "تعذر استعادة جلسة الدخول.",
      );
      setStatus("unavailable");
    }
  }, []);

  useEffect(() => {
    void restoreSession();
  }, [restoreSession]);

  useEffect(() => {
    const expireSession = () => {
      setUser(null);
      setStatus("anonymous");
      setError("انتهت جلسة الدخول. سجّل الدخول مجددًا.");
      void window.desktop.clearAccessToken().catch((clearError: unknown) => {
        setStatus("unavailable");
        setError(
          clearError instanceof Error
            ? clearError.message
            : "تعذر إنهاء جلسة الدخول.",
        );
      });
    };

    window.addEventListener("tadreeb:session-expired", expireSession);
    return () => {
      window.removeEventListener("tadreeb:session-expired", expireSession);
    };
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    setError(null);
    const response = await authApi.login(email, password);
    ensureInstituteOwner(response.data.user);
    await window.desktop.storeAccessToken(response.data.token);
    setUser(response.data.user);
    setStatus("authenticated");
  }, []);

  const logout = useCallback(async () => {
    await window.desktop.clearAccessToken();
    setUser(null);
    setError(null);
    setStatus("anonymous");
  }, []);

  const value = useMemo(
    () => ({ status, user, error, login, logout, restoreSession }),
    [status, user, error, login, logout, restoreSession],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used within AuthProvider");
  return context;
}
