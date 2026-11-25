import PhoneInput, {
  isValidPhoneNumber,
  type Value,
} from "react-phone-number-input";
import arabicLabels from "react-phone-number-input/locale/ar";

export function isValidPhone(value: string) {
  return isValidPhoneNumber(value);
}

export function PhoneNumberField({
  value,
  onChange,
  label,
  disabled = false,
}: {
  value: string;
  onChange(value: string): void;
  label: string;
  disabled?: boolean;
}) {
  return (
    <div className="phone-number-field" dir="ltr">
      <PhoneInput
        aria-label={label}
        autoComplete="tel"
        className="phone-number-control"
        countryCallingCodeEditable={false}
        countrySelectProps={{ "aria-label": "اختيار الدولة" }}
        defaultCountry="YE"
        disabled={disabled}
        international
        labels={arabicLabels}
        onChange={(nextValue?: Value) => onChange(nextValue ?? "")}
        placeholder="رقم الهاتف"
        value={value || undefined}
      />
    </div>
  );
}
