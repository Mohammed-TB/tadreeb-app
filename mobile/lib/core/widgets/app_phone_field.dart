import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    show PhoneNumberException;

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

class AppPhoneField extends StatefulWidget {
  const AppPhoneField({
    super.key,
    this.controller,
    this.initialValue,
    this.defaultCountry = IsoCode.YE,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.isRequired = true,
    this.labelText,
    this.hintText,
    this.errorText,
    this.onSaved,
    this.decoration,
    this.textInputAction,
  }) : assert(
         controller == null || initialValue == null,
         'Provide either a controller or an initial value.',
       );

  final PhoneController? controller;

  /// Accepts a national number or an international number such as +967...
  final String? initialValue;
  final IsoCode defaultCountry;
  final ValueChanged<String?>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final bool isRequired;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final FormFieldSetter<String?>? onSaved;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;

  static PhoneController createController({
    String? initialValue,
    IsoCode defaultCountry = IsoCode.YE,
  }) {
    final phoneNumber = parseValue(
      initialValue,
      defaultCountry: defaultCountry,
    );
    return PhoneController(
      initialValue:
          phoneNumber ?? PhoneNumber(isoCode: defaultCountry, nsn: ''),
    );
  }

  static PhoneNumber? parseValue(
    String? value, {
    IsoCode defaultCountry = IsoCode.YE,
  }) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) return null;

    try {
      return PhoneNumber.parse(trimmedValue, callerCountry: defaultCountry);
    } on PhoneNumberException {
      return null;
    }
  }

  static String? toE164(PhoneNumber? phoneNumber) {
    if (phoneNumber == null ||
        phoneNumber.nsn.isEmpty ||
        !phoneNumber.isValid()) {
      return null;
    }
    return phoneNumber.international;
  }

  @override
  State<AppPhoneField> createState() => _AppPhoneFieldState();
}

class _AppPhoneFieldState extends State<AppPhoneField> {
  late PhoneController _controller;
  late bool _ownsController;
  late bool _hasInvalidInitialValue;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    final parsedInitialValue = AppPhoneField.parseValue(
      widget.initialValue,
      defaultCountry: widget.defaultCountry,
    );
    _hasInvalidInitialValue =
        widget.initialValue?.trim().isNotEmpty == true &&
        parsedInitialValue == null;
    _controller =
        widget.controller ??
        PhoneController(
          initialValue:
              parsedInitialValue ??
              PhoneNumber(isoCode: widget.defaultCountry, nsn: ''),
        );
    if (_controller.value.nsn.isEmpty &&
        _controller.value.isoCode != widget.defaultCountry) {
      _controller.changeCountry(widget.defaultCountry);
    }
  }

  @override
  void didUpdateWidget(covariant AppPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    if (_ownsController) _controller.dispose();
    _ownsController = widget.controller == null;
    final parsedInitialValue = AppPhoneField.parseValue(
      widget.initialValue,
      defaultCountry: widget.defaultCountry,
    );
    _controller =
        widget.controller ??
        PhoneController(
          initialValue:
              parsedInitialValue ??
              PhoneNumber(isoCode: widget.defaultCountry, nsn: ''),
        );
    _hasInvalidInitialValue =
        widget.controller == null &&
        widget.initialValue?.trim().isNotEmpty == true &&
        parsedInitialValue == null;
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  String? _validate(PhoneNumber? phoneNumber) {
    if (widget.errorText != null) return widget.errorText;
    if (_hasInvalidInitialValue && _controller.value.nsn.isEmpty) {
      return 'الرقم المحفوظ غير صحيح، أدخل رقم الهاتف مجددًا';
    }

    final e164Number = AppPhoneField.toE164(phoneNumber);
    if (e164Number == null) {
      if (phoneNumber == null || phoneNumber.nsn.isEmpty) {
        return widget.isRequired ? 'رقم الهاتف مطلوب' : null;
      }
      return 'أدخل رقم هاتف صحيحًا للدولة المحددة';
    }

    return widget.validator?.call(e164Number);
  }

  InputDecoration _buildDecoration() {
    final baseDecoration =
        widget.decoration ??
        InputDecoration(
          filled: true,
          fillColor: AppColors.field,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        );

    return baseDecoration.copyWith(
      labelText: widget.labelText ?? baseDecoration.labelText,
      hintText: widget.hintText ?? baseDecoration.hintText,
      errorText: widget.errorText ?? baseDecoration.errorText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: PhoneFormField(
        key: ObjectKey(_controller),
        controller: _controller,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        isCountrySelectionEnabled: widget.enabled && !widget.readOnly,
        countrySelectorNavigator: CountrySelectorNavigator.dialog(
          height: MediaQuery.sizeOf(context).height * 0.8,
          backgroundColor: AppColors.surface,
          favorites: const [IsoCode.YE],
          showDialCode: true,
          noResultMessage: 'لا توجد دولة مطابقة للبحث',
          searchBoxDecoration: const InputDecoration(
            hintText: 'ابحث باسم أو رمز الدولة',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        countryButtonStyle: const CountryButtonStyle(
          showFlag: true,
          showDialCode: true,
          showIsoCode: false,
          flagSize: 20,
        ),
        textInputAction: widget.textInputAction,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        cursorColor: AppColors.primary,
        decoration: _buildDecoration(),
        validator: _validate,
        onChanged: (phoneNumber) {
          if (_hasInvalidInitialValue) {
            setState(() => _hasInvalidInitialValue = false);
          }
          widget.onChanged?.call(AppPhoneField.toE164(phoneNumber));
        },
        onSaved: (phoneNumber) =>
            widget.onSaved?.call(AppPhoneField.toE164(phoneNumber)),
      ),
    );
  }
}
