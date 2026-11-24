import { useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, Settings2, X } from "lucide-react";
import { instituteApi } from "../api/services";
import {
  ErrorState,
  PageHeader,
  SkeletonRows,
} from "../components/ui";
import { isValidPhone, PhoneNumberField } from "../components/PhoneNumberField";
import type { Institute, InstituteSettings } from "../types";

export function SettingsPage() {
  const queryClient = useQueryClient();
  const [feedback, setFeedback] = useState("");
  const institute = useQuery({
    queryKey: ["institute"],
    queryFn: instituteApi.getMine,
  });
  const settings = useQuery({
    queryKey: ["institute-settings"],
    queryFn: instituteApi.getSettings,
  });

  const saveInstitute = useMutation({
    mutationFn: instituteApi.update,
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ["institute"] }),
        queryClient.invalidateQueries({ queryKey: ["dashboard"] }),
      ]);
      setFeedback("تم حفظ بيانات المعهد.");
    },
    onError: (error) => setFeedback(error.message),
  });

  const saveSettings = useMutation({
    mutationFn: instituteApi.updateSettings,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["institute-settings"] });
      setFeedback("تم حفظ سياسة الدفع.");
    },
    onError: (error) => setFeedback(error.message),
  });

  return (
    <div className="page-stack">
      <PageHeader
        title="الإعدادات"
        description="حدّث بيانات المعهد واضبط طريقة سداد الأرصدة ومهلة إعادة رفع السند."
      />

      {feedback && (
        <div className="toast-message" role="status">
          <span>{feedback}</span>
          <button aria-label="إغلاق الرسالة" className="icon-button" onClick={() => setFeedback("")}>
            <X size={15} />
          </button>
        </div>
      )}

      {institute.isPending ? (
        <section className="panel settings-panel"><SkeletonRows count={2} /></section>
      ) : institute.isError ? (
        <section className="panel settings-panel">
          <ErrorState message={institute.error.message} onRetry={() => void institute.refetch()} />
        </section>
      ) : (
        <InstituteProfileForm
          institute={institute.data}
          isSaving={saveInstitute.isPending}
          onSave={(input) => {
            setFeedback("");
            saveInstitute.mutate(input);
          }}
        />
      )}

      {settings.isPending ? (
        <section className="panel settings-panel"><SkeletonRows count={2} /></section>
      ) : settings.isError ? (
        <section className="panel settings-panel">
          <ErrorState message={settings.error.message} onRetry={() => void settings.refetch()} />
        </section>
      ) : (
        <PaymentSettingsForm
          isSaving={saveSettings.isPending}
          onSave={(input) => {
            setFeedback("");
            saveSettings.mutate(input);
          }}
          settings={settings.data}
        />
      )}
    </div>
  );
}

function InstituteProfileForm({
  institute,
  isSaving,
  onSave,
}: {
  institute: Institute;
  isSaving: boolean;
  onSave(input: Partial<Institute>): void;
}) {
  const [name, setName] = useState(institute.name);
  const [description, setDescription] = useState(institute.description ?? "");
  const [phone, setPhone] = useState(institute.phone ?? "");
  const [email, setEmail] = useState(institute.email ?? "");
  const [address, setAddress] = useState(institute.address ?? "");
  const [logo, setLogo] = useState(institute.logo ?? "");
  const [error, setError] = useState("");

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmedName = name.trim();
    const trimmedAddress = address.trim();
    if (!trimmedName || !trimmedAddress) {
      setError("اسم المعهد والعنوان مطلوبان.");
      return;
    }
    if (email.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      setError("أدخل بريدًا إلكترونيًا صحيحًا أو اترك الحقل فارغًا.");
      return;
    }
    if (phone && !isValidPhone(phone)) {
      setError("أدخل رقم هاتف صحيحًا أو اترك الحقل فارغًا.");
      return;
    }
    setError("");
    onSave({
      name: trimmedName,
      description: description.trim(),
      phone: phone.trim(),
      email: email.trim(),
      address: trimmedAddress,
      logo: logo.trim(),
    });
  };

  return (
    <section className="panel settings-panel">
      <div className="settings-heading">
        <div className="settings-icon"><Settings2 size={19} /></div>
        <div>
          <h2>بيانات المعهد</h2>
          <p>المعلومات التي تظهر للطلاب في التطبيق.</p>
        </div>
      </div>
      <form className="settings-form" onSubmit={submit}>
        <div className="form-grid">
          <label className="form-field">
            اسم المعهد
            <input className="form-control" maxLength={150} onChange={(event) => setName(event.target.value)} required value={name} />
          </label>
          <label className="form-field">
            رقم الهاتف
            <PhoneNumberField
              label="رقم هاتف المعهد"
              onChange={setPhone}
              value={phone}
            />
          </label>
          <label className="form-field">
            البريد الإلكتروني
            <input className="form-control latin-number" onChange={(event) => setEmail(event.target.value)} type="email" value={email} />
          </label>
          <label className="form-field">
            العنوان
            <input className="form-control" onChange={(event) => setAddress(event.target.value)} required value={address} />
          </label>
          <label className="form-field form-field-wide">
            وصف المعهد
            <textarea className="form-control" maxLength={2000} onChange={(event) => setDescription(event.target.value)} rows={3} value={description} />
          </label>
          <label className="form-field form-field-wide">
            رابط الشعار
            <input className="form-control latin-number" onChange={(event) => setLogo(event.target.value)} placeholder="https://..." type="url" value={logo} />
            <span className="form-help">تغيير الشعار متاح عبر رابط الصورة؛ لا يوجد مسار رفع ملفات ضمن الـ API الحالي.</span>
          </label>
        </div>
        {error && <div className="form-error" role="alert">{error}</div>}
        <div className="form-actions">
          <button className="button button-primary" disabled={isSaving} type="submit">
            <Check size={16} /> {isSaving ? "جارٍ الحفظ..." : "حفظ بيانات المعهد"}
          </button>
        </div>
      </form>
    </section>
  );
}

function PaymentSettingsForm({
  settings,
  isSaving,
  onSave,
}: {
  settings: InstituteSettings;
  isSaving: boolean;
  onSave(input: Partial<InstituteSettings>): void;
}) {
  const [policy, setPolicy] = useState(settings.balancePaymentPolicy);
  const [minimum, setMinimum] = useState(String(settings.minimumInstallmentAmount));
  const [hours, setHours] = useState(String(settings.receiptResubmissionHours));
  const [error, setError] = useState("");

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const minimumAmount = Number(minimum);
    const resubmissionHours = Number(hours);
    if (!Number.isFinite(minimumAmount) || minimumAmount <= 0) {
      setError("الحد الأدنى للقسط يجب أن يكون مبلغًا أكبر من صفر.");
      return;
    }
    if (!Number.isInteger(resubmissionHours) || resubmissionHours < 1 || resubmissionHours > 72) {
      setError("مهلة إعادة رفع السند يجب أن تكون من ساعة إلى 72 ساعة.");
      return;
    }
    setError("");
    onSave({
      balancePaymentPolicy: policy,
      minimumInstallmentAmount: minimumAmount,
      receiptResubmissionHours: resubmissionHours,
    });
  };

  return (
    <section className="panel settings-panel">
      <div className="settings-heading">
        <div className="settings-icon settings-icon-gold"><Settings2 size={19} /></div>
        <div>
          <h2>سياسة الدفعات</h2>
          <p>تُطبّق على دفعات الرصيد الجديدة، أما الدفعات المعلقة فتظل بانتظار المراجعة.</p>
        </div>
      </div>
      <form className="settings-form" onSubmit={submit}>
        <div className="form-grid">
          <label className="form-field">
            سياسة سداد الرصيد
            <select
              className="form-control"
              onChange={(event) => setPolicy(event.target.value === "installments" ? "installments" : "fullRemainder")}
              value={policy}
            >
              <option value="fullRemainder">دفع كامل المبلغ المتبقي</option>
              <option value="installments">السداد على أقساط</option>
            </select>
            <span className="form-help">
              {policy === "fullRemainder"
                ? "يلزم تسديد كامل الرصيد المتبقي في دفعة واحدة."
                : "يمكن تسجيل عدة دفعات، ولا تقل الدفعة عن الحد الأدنى إلا إذا كانت هي آخر مبلغ متبقٍ."}
            </span>
          </label>
          <label className="form-field">
            الحد الأدنى للقسط <span className="form-help">بالريال اليمني · ر.ي</span>
            <input
              className="form-control latin-number"
              disabled={policy !== "installments"}
              min="0.01"
              onChange={(event) => setMinimum(event.target.value)}
              required
              step="0.01"
              type="number"
              value={minimum}
            />
          </label>
          <label className="form-field">
            مهلة إعادة رفع السند
            <input
              className="form-control latin-number"
              max="72"
              min="1"
              onChange={(event) => setHours(event.target.value)}
              required
              step="1"
              type="number"
              value={hours}
            />
            <span className="form-help">عدد الساعات المسموح بها بعد رفض سند التحويل، بحد أقصى 72 ساعة.</span>
          </label>
        </div>
        {error && <div className="form-error" role="alert">{error}</div>}
        <div className="form-actions">
          <button className="button button-primary" disabled={isSaving} type="submit">
            <Check size={16} /> {isSaving ? "جارٍ الحفظ..." : "حفظ سياسة الدفع"}
          </button>
        </div>
      </form>
    </section>
  );
}
