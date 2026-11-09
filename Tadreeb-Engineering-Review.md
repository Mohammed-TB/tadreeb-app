# التقرير الهندسي لمشروع Tadreeb Flutter

> **نطاق المراجعة:** فحص قراءة فقط للحالة الحالية لملفات Flutter والباك إند الموجودة في مساحة العمل. لم تُعدّل ملفات التطبيق ولم تُحذف بيانات Mock. لم تُعرض أسرار أو محتويات ملفات إعدادات سرية.

## 1. ملخص حالة المشروع

- المشروع منظم جزئيًا بأسلوب **Feature-first**: توجد مجلدات للمصادقة والطلاب والمعاهد والدورات والتسجيلات، إلى جانب `app` و`core`.
- المصادقة الحالية تجريبية بالكامل؛ التسجيل والدخول في `mobile/lib/features/auth/services/auth_service.dart` يعملان على قوائم داخل الذاكرة ولا يرسلان طلبات إلى الباك إند.
- تبعيات `http` و`flutter_secure_storage` و`google_sign_in` موجودة في `mobile/pubspec.yaml`، لكن لم يُعثر على استخدامها في كود Dart للاتصال أو التخزين أو تسجيل Google.
- Provider وGoRouter مجهزان لتحديث التوجيه بحسب حالة المصادقة ودور المستخدم، لكن الحالة حاليًا مؤقتة وتعتمد على مستخدم Mock.
- توجد تغييرات وملفات غير متتبعة سابقة في شجرة العمل، ومنها ملفات المصادقة والباك إند. لم تُعدّل هذه التغييرات أثناء إعداد التقرير.
- لم يُشغّل التطبيق أو الاختبارات؛ لذا تحتاج سلوكيات الشبكة وإعداد OAuth على الأجهزة إلى تحقق وقت التنفيذ.

## 2. شجرة مجلدات `mobile/lib`

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme/
│       ├── app_colors.dart
│       ├── app_fonts.dart
│       ├── app_spacing.dart
│       ├── app_theme.dart
│       └── app_typography.dart
├── core/
│   ├── mock_data/
│   │   ├── auth_data.dart
│   │   ├── categories_data.dart
│   │   ├── courses_data.dart
│   │   ├── institutes_data.dart
│   │   ├── students_data.dart
│   │   └── users_data.dart
│   └── widgets/
│       ├── app_drawer.dart
│       ├── app_shell.dart
│       ├── button.dart
│       ├── search.dart
│       ├── text_filed.dart
│       └── text_filed_form.dart
└── features/
    ├── admin/
    │   ├── routing/
    │   │   └── admin_shell.dart
    │   └── screens/
    │       ├── admin_dashboard_screen.dart
    │       ├── admin_institutes_screen.dart
    │       ├── admin_more_screen.dart
    │       └── admin_users_screen.dart
    ├── auth/
    │   ├── controllers/auth_controller.dart
    │   ├── models/user_model.dart
    │   ├── screens/
    │   │   ├── login_screen.dart
    │   │   └── register_screen.dart
    │   ├── services/auth_service.dart
    │   └── widgets/
    │       ├── form_login.dart
    │       ├── form_register.dart
    │       └── top_header.dart
    ├── courses/
    │   ├── controllers/course_controller.dart
    │   ├── models/course_model.dart
    │   └── services/course_service.dart
    ├── enrollments/
    │   ├── controllers/enrollment_controller.dart
    │   ├── models/
    │   │   ├── booking_settings_model.dart
    │   │   ├── enrollment_model.dart
    │   │   └── payment_model.dart
    │   ├── repositories/
    │   │   ├── enrollment_repository.dart
    │   │   └── mock_enrollment_repository.dart
    │   └── services/enrollment_service.dart
    ├── institutes/
    │   ├── controllers/institute_controller.dart
    │   ├── models/institute_model.dart
    │   ├── routing/institute_shell.dart
    │   ├── screens/
    │   │   ├── institute_bookings_screen.dart
    │   │   ├── institute_courses_screen.dart
    │   │   ├── institute_dashboard_screen.dart
    │   │   └── institute_students_screen.dart
    │   └── services/institute_service.dart
    ├── onboarding/
    │   ├── models/onboarding.models.dart
    │   ├── screens/onboarding_screen.dart
    │   └── widgets/on_boarding_button.dart
    └── students/
        ├── models/student_model.dart
        ├── routing/student_shell.dart
        ├── screens/
        │   ├── bookings_screen.dart
        │   ├── course_details_screen.dart
        │   ├── course_registration_screen.dart
        │   ├── courses_screen.dart
        │   └── home_screen.dart
        └── widgets/
            ├── course_card.dart
            ├── featured_courses_carousel.dart
            ├── header_home.dart
            ├── institute_card.dart
            ├── list_category.dart
            ├── most_popular_courses.dart
            └── most_popular_institutes.dart
```

**تقييم البنية:** تنظيم الميزات واضح إجمالًا. لا توجد حاليًا طبقة `core/network` أو API أو مستودع للمصادقة. تسجيلات الدورات لديها واجهة Repository ونسخة Mock، بينما المصادقة والدورات والمعاهد تعتمد مباشرة على خدمات وبيانات Mock. `StudentModel` يرث من `UserModel` دون إضافة حقول؛ هذا تداخل بسيط في النمذجة، وليس دليلًا مؤكدًا على تكرار غير ضروري. لم يُحسم وجود تكرار وظيفي بين كل الواجهات أو Widgets.

## 3. الملفات الموجودة المسؤولة عن المصادقة

- `mobile/lib/features/auth/controllers/auth_controller.dart`: يحتفظ بالمستخدم الحالي وحالة التحميل والخطأ، ويستدعي الخدمة، ويوفر `logout()` محليًا.
- `mobile/lib/features/auth/services/auth_service.dart`: ينفذ التسجيل والتحقق من الدخول باستخدام قوائم Mock داخل الذاكرة.
- `mobile/lib/features/auth/models/user_model.dart`: نموذج المستخدم وأدواره.
- `mobile/lib/features/auth/screens/login_screen.dart` و`mobile/lib/features/auth/widgets/form_login.dart`: شاشة ونموذج الدخول.
- `mobile/lib/features/auth/screens/register_screen.dart` و`mobile/lib/features/auth/widgets/form_register.dart`: شاشة ونموذج التسجيل والتحقق من تطابق كلمة المرور.
- `mobile/lib/core/mock_data/auth_data.dart` و`mobile/lib/core/mock_data/users_data.dart`: بيانات حسابات ومستخدمين تجريبية.
- `mobile/lib/core/widgets/app_drawer.dart`: يستدعي `AuthController.logout()` عند اختيار تسجيل الخروج.

### سلوك المصادقة الحالي

- **التسجيل والدخول:** تجريبيان ولا يتصلان بالباك إند. الحساب الجديد يضاف إلى قوائم داخل الذاكرة، لذلك لا يستمر بعد إغلاق التطبيق.
- **حفظ المستخدم:** `currentUser` حقل داخل `AuthController` فقط.
- **إدارة حالة الدخول:** Provider يتيح قراءة المتحكم، و`ChangeNotifier` يبلغ المستمعين بالتغييرات.
- **استعادة الجلسة:** غير موجودة.
- **Logout:** يمسح المستخدم محليًا فقط. لا يوجد Token لحذفه، ولا طلب إبطال للجلسة على الخادم.
- **Google:** زرّا الدخول والتسجيل يعرضان رسالة أن الميزة ستُفعّل لاحقًا ولا ينفذان عملية مصادقة.

## 4. الملفات الموجودة المسؤولة عن API

لم يُعثر داخل `mobile/lib` على عميل HTTP أو Base URL أو `Authorization` أو طلبات API. تبعية `http` موجودة في `mobile/pubspec.yaml` فقط.

مصادر البيانات التجريبية ذات الصلة:

- `mobile/lib/features/courses/services/course_service.dart`: يعتمد على بيانات Mock للدورات.
- `mobile/lib/features/institutes/services/institute_service.dart`: يعتمد على بيانات Mock للمعاهد.
- `mobile/lib/features/enrollments/repositories/enrollment_repository.dart` و`mobile/lib/features/enrollments/repositories/mock_enrollment_repository.dart`: واجهة ونسخة Mock لتسجيلات الدورات.
- لا يوجد `ApiClient` أو `ApiService` أو ملف API constants في شجرة Flutter.

بالتالي، لا توجد معالجة لأخطاء HTTP أو مهلات الاتصال أو انقطاع الإنترنت أو إرسال Bearer Token.

## 5. الملفات الموجودة المسؤولة عن التخزين

لم يُعثر على خدمة Dart تستخدم `flutter_secure_storage`، رغم وجود التبعية في `mobile/pubspec.yaml`. لا يُحفظ JWT، ولا يوجد حذف Token عند الخروج، ولا استعادة جلسة عند التشغيل.

## 6. تقييم ربط Flutter بالباك إند

ملفات الباك إند التي فُحصت:

- `Tadreeb-Backend/src/modules/auth/auth.routes.ts`
- `Tadreeb-Backend/src/modules/auth/auth.controller.ts`
- `Tadreeb-Backend/src/modules/auth/auth.service.ts`
- `Tadreeb-Backend/src/middlewares/auth.middleware.ts`
- `Tadreeb-Backend/src/app.ts`

المسارات معرفة تحت `/api/auth`. التسجيل وتسجيل الدخول وGoogle يعيدون `user` و`token` داخل `data`. وسيط المصادقة يتوقع `Authorization: Bearer <token>`، وJWT يصدر بصلاحية سبعة أيام. تسجيل البريد ينشئ طالبًا، أما الدخول بالبريد فيقبل المستخدم المسجل بحسب بياناته ودوره. Google مخصص للطلاب بحسب منطق الخدمة.

### نقاط عدم التوافق والنقص

- Flutter لا يرسل طلبات إلى هذه المسارات ولا يحدد Base URL. لم يُعثر في كود Flutter على `localhost` أو `10.0.2.2`.
- مسار `/me` يعيد من الوسيط `userId` و`role` فقط، وبنية مختلفة عن `data.user` في الدخول والتسجيل؛ هذه البيانات وحدها لا تعيد بناء ملف المستخدم الكامل.
- استجابة الدخول والتسجيل تتضمن `id`, `name`, `email`, `role`, `status`، لكنها لا تتضمن `phone` أو `authProvider`.
- لا يظهر مسار logout في مسارات الباك إند. حذف Token من الجهاز ينهي الجلسة محليًا، لكنه لا يبطل JWT الصالح لدى الخادم.
- إذن `INTERNET` موجود في `mobile/android/app/src/main/AndroidManifest.xml`، ومعرّف التطبيق `com.tadreeb.app` موجود في `mobile/android/app/build.gradle.kts`. إعداد السماح باتصالات HTTP غير المشفرة لم يُحسم من الملفات المفحوصة؛ يلزم التحقق منه لبيئة التطوير على Android.

## 7. تقييم Google Sign-In

- الإصدار `google_sign_in: ^7.2.0` معلن في `mobile/pubspec.yaml`.
- لا يوجد استخدام في Dart لـ`GoogleSignIn` أو تهيئة للمكتبة أو استخراج ID Token أو إرساله للخادم.
- أزرار Google في `mobile/lib/features/auth/widgets/form_login.dart` و`mobile/lib/features/auth/widgets/form_register.dart` تعرض رسائل «سيتم التفعيل قريبًا» فقط.
- الباك إند يتوقع `idToken` في `/api/auth/google` ويتحقق منه، ويقصر Google Login على الطلاب.
- معرّف تطبيق Android ظاهر في إعداد Gradle، لكن لا يمكن تأكيد اكتمال إعدادات OAuth أو بصمات التوقيع من الملفات التي فُحصت.
- التنفيذ لاحقًا يجب أن يتبع API الإصدار 7.x، لا أمثلة الإصدارات القديمة: استخدام `GoogleSignIn.instance` وتهيئة المكتبة بالطريقة المتوافقة مع الإصدار، ثم المصادقة واستخراج ID Token وإرساله إلى الباك إند.

**الربط المطلوب:** إضافة تدفق Google إلى خدمة المصادقة، استدعاؤه عبر `AuthController`، وإرسال ID Token إلى `/api/auth/google` ثم حفظ JWT الصادر عن Tadreeb بأمان.

## 8. تقييم Provider وGoRouter

- `mobile/lib/main.dart` يسجل `AuthController` عبر `ChangeNotifierProvider` مع `AuthService`، ويسجل متحكمات الدورات والمعاهد والتسجيلات.
- شاشات الدخول والتسجيل تصل إلى المتحكم عبر Provider.
- `mobile/lib/app/app.dart` يبني GoRouter ويستخدم المتحكم في `refreshListenable` و`redirect`.
- التوجيه والحماية الحاليان يفرّقان بين الطالب وصاحب المعهد والمسؤول. هذه حماية على مستوى التطبيق وليست بديلًا عن صلاحيات الخادم.
- الدخول يوجه حسب الدور. التسجيل يوجه إلى واجهة الطالب، بما يتفق مع مسار تسجيل الطالب في الباك إند.
- بعد إعادة تشغيل التطبيق ستكون حالة المتحكم فارغة لعدم وجود استعادة جلسة؛ ومحاولة فتح مسار محمي ستوجه المستخدم إلى `/login`.

## 9. مقارنة UserModel في Flutter وNode.js

Flutter: `mobile/lib/features/auth/models/user_model.dart`.

Node.js: `Tadreeb-Backend/src/modules/users/user.model.ts`.

| الحقل | Flutter | Node.js / استجابة API | الملاحظة |
|---|---|---|---|
| المعرّف | `id` | MongoDB يستخدم `_id`، والاستجابة الآمنة تحولها إلى `id` | متوافق مع استجابة API الآمنة، لا مع وثيقة Mongo الخام |
| `name` | موجود | موجود | متوافق |
| `email` | موجود | موجود | متوافق |
| `phone` | اختياري | اختياري | موجود في النموذجين لكنه غير مرسل في الاستجابة الآمنة الحالية |
| `role` | `student`, `instituteOwner`, `admin` | القيم النصية نفسها | متوافق |
| `status` | غير موجود | موجود، ويعاد في استجابة الدخول والتسجيل | يلزم الاتفاق على تمثيله في Flutter |
| `authProvider` | غير موجود | موجود في النموذج، ولا يعاد في الاستجابة الآمنة الحالية | يلزم الاتفاق على الحاجة إليه وإرساله |
| تحويل JSON | لا يوجد `fromJson`/`toJson` | استجابة JSON | يلزم إضافة تحليل صريح وتوحيد شكل `/me` مع بقية المسارات |

## 10. المشكلات والنواقص

1. **مصادقة Mock:** `mobile/lib/features/auth/services/auth_service.dart` يستخدم `mobile/lib/core/mock_data/auth_data.dart` و`mobile/lib/core/mock_data/users_data.dart`.
2. **الجلسة غير دائمة:** `mobile/lib/features/auth/controllers/auth_controller.dart` يحتفظ بالمستخدم في الذاكرة فقط.
3. **غياب طبقة API:** لا يوجد عميل موحد أو معالجة لأخطاء الشبكة والمهلات.
4. **غياب التخزين الآمن:** التبعية موجودة دون استخدام، ولا توجد استعادة جلسة.
5. **Google غير منفذ:** عناصر الواجهة لا تنفذ تسجيل الدخول أو التسجيل.
6. **نموذج Flutter غير مكتمل للتكامل:** `user_model.dart` يفتقر لتحويل JSON وحقلي `status` و`authProvider`.
7. **استجابة `/me` محدودة:** `Tadreeb-Backend/src/modules/auth/auth.routes.ts` يعيد بيانات مصادقة محدودة، لا ملف المستخدم الآمن الكامل.
8. **Logout محلي:** `mobile/lib/core/widgets/app_drawer.dart` يمسح حالة الواجهة فقط؛ لا يوجد إبطال Token من الخادم.
9. **اتصال التطوير عبر HTTP:** يلزم التحقق من إعداد Android الخاص باتصالات cleartext.
10. **ميزات أخرى تستخدم Mock أيضًا:** مثل `mobile/lib/features/courses/services/course_service.dart` و`mobile/lib/features/institutes/services/institute_service.dart` ومستودع التسجيلات التجريبي. تحويل المصادقة وحدها لا يحول بيانات بقية الميزات.

## 11. الملفات التي تحتاج تعديلًا عند اعتماد التنفيذ

### Flutter

- `mobile/lib/features/auth/services/auth_service.dart`: ربط العمليات بمسارات API.
- `mobile/lib/features/auth/controllers/auth_controller.dart`: إضافة استعادة الجلسة وGoogle وحالة التهيئة.
- `mobile/lib/features/auth/models/user_model.dart`: تحويل JSON والحقول المتفق عليها.
- `mobile/lib/main.dart`: تسجيل خدمات الشبكة والتخزين وبدء استعادة الجلسة.
- `mobile/lib/app/app.dart`: مراعاة حالة التهيئة في التوجيه مع إبقاء قواعد الأدوار.
- `mobile/lib/features/auth/screens/login_screen.dart` و`mobile/lib/features/auth/screens/register_screen.dart`: ربط التدفقات الحالية دون تغيير التصميم.
- `mobile/lib/features/auth/widgets/form_login.dart` و`mobile/lib/features/auth/widgets/form_register.dart`: ربط أزرار Google الحالية بتدفق فعلي مع الحفاظ على الواجهة.

### الباك إند، إذا اعتُمد تحسين `/me` أو إبطال الجلسة خادميًا

- `Tadreeb-Backend/src/modules/auth/auth.routes.ts`
- `Tadreeb-Backend/src/middlewares/auth.middleware.ts`
- وقد يتطلب ذلك تعديل `Tadreeb-Backend/src/modules/auth/auth.controller.ts` أو `Tadreeb-Backend/src/modules/auth/auth.service.ts` بحسب تصميم الاستجابة وآلية إبطال الجلسة.

## 12. الملفات المقترح إنشاؤها

- `mobile/lib/core/network/api_client.dart`: عميل HTTP موحد، الترويسات والمهلات ومعالجة الأخطاء.
- `mobile/lib/core/network/api_constants.dart`: Base URL والمسارات وإعدادات البيئة.
- `mobile/lib/features/auth/services/token_storage_service.dart`: واجهة تخزين وقراءة وحذف JWT باستخدام `flutter_secure_storage`.

يمكن تطوير `AuthService` الحالي دون إنشاء Repository للمصادقة؛ إضافة Repository خيار تنظيمي لاحق وليست شرطًا لإكمال المطلوب.

## 13. خطة التنفيذ المرتبة

1. اعتماد صيغة JSON النهائية لمسارات التسجيل والدخول وGoogle و`/me`، وحسم اختلاف `/me`.
2. إنشاء عميل API موحد وتحديد Base URL حسب البيئة، والتحقق من إعداد HTTP المحلي على Android.
3. إنشاء خدمة تخزين Token آمنة وربطها بتسجيل الدخول والتسجيل وGoogle.
4. تحديث `UserModel` لدعم JSON والحقول المتفق عليها وتحويل الدور والمعرّف صراحة.
5. ربط `AuthService` بالباك إند، وتحويل أخطاء HTTP والشبكة إلى أخطاء مفهومة للشاشات.
6. إضافة استعادة الجلسة عند بدء التطبيق واستدعاء `/me` للتحقق من Token وجلب بيانات المستخدم.
7. ربط نماذج الدخول والتسجيل الحالية بـAPI، وربط Google باستخدام واجهة `google_sign_in` 7.x وإرسال ID Token.
8. جعل logout يمسح المستخدم وToken محليًا؛ وإضافة إبطال خادمي فقط إذا تقرر أن ذلك مطلوب.
9. إبقاء قواعد التوجيه حسب الدور واختبار دخول الأدوار والاستعادة والخروج والأخطاء وانقطاع الشبكة.
10. في مرحلة منفصلة، نقل مصادر الدورات والمعاهد والتسجيلات من Mock إلى API مع الحفاظ على التصاميم.

## الخلاصة

أساس Provider والتوجيه بحسب الدور موجود، لكن الاتصال الحقيقي للمصادقة والتخزين الآمن واستعادة الجلسة وGoogle Sign-In غير منفذة في Flutter. يوصى بتنفيذ الخطة بعد مراجعة التقرير واعتماده، مع الإبقاء على بيانات Mock والتصاميم الحالية إلى حين الموافقة على بدء التنفيذ.
