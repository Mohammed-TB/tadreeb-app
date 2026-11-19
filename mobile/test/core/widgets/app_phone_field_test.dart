import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:project_1/app/theme/app_colors.dart';
import 'package:project_1/core/widgets/app_phone_field.dart';

Widget _buildPhoneField({
  required GlobalKey<FormState> formKey,
  required PhoneController controller,
  ValueChanged<String?>? onChanged,
  bool isRequired = true,
  FormFieldSetter<String?>? onSaved,
}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: [
      ...GlobalMaterialLocalizations.delegates,
      ...PhoneFieldLocalization.delegates,
    ],
    home: Scaffold(
      body: Form(
        key: formKey,
        child: AppPhoneField(
          controller: controller,
          labelText: 'رقم الهاتف',
          isRequired: isRequired,
          onChanged: onChanged,
          onSaved: onSaved,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('defaults to Yemen and returns a valid E.164 number', (
    tester,
  ) async {
    final controller = AppPhoneField.createController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();
    String? changedNumber;

    await tester.pumpWidget(
      _buildPhoneField(
        formKey: formKey,
        controller: controller,
        onChanged: (value) => changedNumber = value,
      ),
    );

    expect(controller.value.isoCode, IsoCode.YE);
    await tester.enterText(find.byType(TextField), '777123456');
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isTrue);
    expect(changedNumber, '+967777123456');
    expect(AppPhoneField.toE164(controller.value), '+967777123456');
  });

  testWidgets('keeps entered digits in left-to-right order in Arabic UI', (
    tester,
  ) async {
    final controller = AppPhoneField.createController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _buildPhoneField(formKey: formKey, controller: controller),
    );
    await tester.enterText(find.byType(TextField), '774899332');
    await tester.pumpAndSettle();

    final editableTextContext = tester.element(find.byType(EditableText));
    expect(Directionality.of(editableTextContext), TextDirection.ltr);
    expect(controller.value.nsn, '774899332');
    expect(AppPhoneField.toE164(controller.value), '+967774899332');
  });

  testWidgets('rejects invalid numbers with an Arabic error', (tester) async {
    final controller = AppPhoneField.createController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _buildPhoneField(formKey: formKey, controller: controller),
    );
    await tester.enterText(find.byType(TextField), '123');
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('أدخل رقم هاتف صحيحًا للدولة المحددة'), findsOneWidget);
  });

  testWidgets('allows an empty optional number and saves null', (tester) async {
    final controller = AppPhoneField.createController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();
    String? savedNumber = 'not saved';

    await tester.pumpWidget(
      _buildPhoneField(
        formKey: formKey,
        controller: controller,
        isRequired: false,
        onSaved: (value) => savedNumber = value,
      ),
    );

    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();
    expect(savedNumber, isNull);
  });

  testWidgets('accepts a pasted international number without duplication', (
    tester,
  ) async {
    final controller = AppPhoneField.createController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _buildPhoneField(formKey: formKey, controller: controller),
    );
    await tester.enterText(find.byType(TextField), '+12025550123');
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isTrue);
    expect(controller.value.isoCode, IsoCode.US);
    expect(AppPhoneField.toE164(controller.value), '+12025550123');
  });

  testWidgets('searches countries by localized name and dial code', (
    tester,
  ) async {
    final controller = AppPhoneField.createController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _buildPhoneField(formKey: formKey, controller: controller),
    );
    await tester.tap(find.byKey(const ValueKey('country-code-chip')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
      AppColors.surface,
    );
    final searchField = find.byType(TextField).last;
    expect(
      tester.widget<TextField>(searchField).decoration!.hintText,
      'ابحث باسم أو رمز الدولة',
    );
    await tester.enterText(searchField, '967');
    await tester.pumpAndSettle();
    expect(find.text('اليمن'), findsOneWidget);

    await tester.enterText(searchField, 'اليمن');
    await tester.pumpAndSettle();
    expect(find.text('اليمن'), findsNWidgets(2));
  });

  test('normalizes international numbers from multiple countries', () {
    final yemen = AppPhoneField.parseValue('0777123456');
    final unitedStates = AppPhoneField.parseValue('+12025550123');

    expect(AppPhoneField.toE164(yemen), '+967777123456');
    expect(AppPhoneField.toE164(unitedStates), '+12025550123');
  });
}
