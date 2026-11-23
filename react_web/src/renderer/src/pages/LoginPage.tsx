import { useState, type FormEvent } from "react";
import { ArrowLeft, BookOpenCheck, Eye, EyeOff, LockKeyhole, Mail } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function LoginPage() {
  const { login, error: sessionError } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [formError, setFormError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setFormError("");
    setSubmitting(true);
    try {
      await login(email.trim(), password);
      navigate("/dashboard", { replace: true });
    } catch (error) {
      setFormError(
        error instanceof Error ? error.message : "تعذر تسجيل الدخول.",
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="login-screen" dir="rtl">
      <section className="login-brand-panel">
        <div className="login-brand">
          <div className="brand-mark brand-mark-large">
            <BookOpenCheck size={27} strokeWidth={2.1} />
          </div>
          <span>تدريب</span>
        </div>
        <div className="login-brand-copy">
          <span className="eyebrow-light">مساحة عملك، بصورة أوضح</span>
          <h1>كل تفاصيل معهدك<br />في مكان واحد.</h1>
          <p>
            تابع الدورات والحجوزات والإيرادات من لوحة مصممة لتسهّل عليك قراءة
            البيانات واتخاذ القرار.
          </p>
        </div>
        <div className="login-decoration login-decoration-one" />
        <div className="login-decoration login-decoration-two" />
        <div className="login-brand-foot">
          <span className="brand-foot-dot" />
          لوحة خاصة بأصحاب المعاهد
        </div>
      </section>

      <section className="login-form-panel">
        <div className="login-form-wrap">
          <div className="login-form-heading">
            <span className="eyebrow">مرحبًا بعودتك</span>
            <h2>تسجيل الدخول</h2>
            <p>أدخل بيانات حساب صاحب المعهد للمتابعة.</p>
          </div>

          <form className="login-form" onSubmit={submit}>
            <label htmlFor="email">البريد الإلكتروني</label>
            <div className="input-wrap">
              <Mail size={18} />
              <input
                autoComplete="username"
                id="email"
                name="email"
                onChange={(event) => setEmail(event.target.value)}
                placeholder="name@example.com"
                required
                type="email"
                value={email}
              />
            </div>

            <label htmlFor="password">كلمة المرور</label>
            <div className="input-wrap">
              <LockKeyhole size={18} />
              <input
                autoComplete="current-password"
                id="password"
                name="password"
                onChange={(event) => setPassword(event.target.value)}
                placeholder="أدخل كلمة المرور"
                required
                type={showPassword ? "text" : "password"}
                value={password}
              />
              <button
                aria-label={showPassword ? "إخفاء كلمة المرور" : "إظهار كلمة المرور"}
                className="password-toggle"
                onClick={() => setShowPassword((visible) => !visible)}
                type="button"
              >
                {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
              </button>
            </div>

            {(formError || sessionError) && (
              <div className="form-alert" role="alert">
                {formError || sessionError}
              </div>
            )}

            <button className="button button-primary login-submit" disabled={submitting}>
              <span>{submitting ? "جارٍ التحقق..." : "دخول إلى لوحة المعهد"}</span>
              <ArrowLeft size={18} />
            </button>
          </form>

          <div className="login-secure-note">
            <LockKeyhole size={15} />
            تُحفظ الجلسة على هذا الجهاز بطريقة مشفّرة.
          </div>
        </div>
        <span className="login-copyright">تدريب · إدارة المعاهد والدورات</span>
      </section>
    </main>
  );
}
