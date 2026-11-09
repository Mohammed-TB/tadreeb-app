# Tadreeb App - Local Demo

## Run

From the `mobile` directory:

```shell
flutter pub get
flutter run
```

Authentication uses the Tadreeb backend. Course, institute, and booking data
remain demo data in memory; booking and payment actions are not submitted to
the server.

## Demo accounts

Create a student account through the app or use credentials for an account
already registered in the backend. Institute-owner access requires a backend
account with that role. No demo credentials are used by the authentication
service.

## Backend and Google Sign-In setup

The Android emulator uses `http://10.0.2.2:5000` by default. Override the API
origin when running on another device or environment:

```shell
flutter run --dart-define=API_BASE_URL=http://localhost:5000
```

For Google Sign-In, provide the Web OAuth Client ID (the public client ID, not
a client secret) at build/run time. It must match the audience configured by
the backend:

```shell
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID
```

Configure the Android OAuth client for package `com.tadreeb.app` and the
signing certificate used for the build. Debug and profile Android manifests
allow cleartext HTTP for local development; production builds should use
HTTPS and a production `API_BASE_URL`.

## Try the student booking flow

1. Sign in as the student and open a course.
2. Select registration, choose a deposit or full payment, and attach a receipt
   image from the device.
3. Submit the booking. It reserves a seat and appears in **My Bookings**.
4. Sign out, then sign in as the institute owner.
5. Open **Bookings**, view the receipt, then approve or reject the request.
6. Sign back in as the student to see the updated status. A rejected request can
   be resubmitted before its deadline.

The receipt is only a local file path; it is not uploaded. The institute review
screen can display it only when that file is accessible on the same device.
Course capacity and booking state are simulated in memory for this demo.

## Verification

```shell
flutter test
flutter analyze
```

---

# تقرير تحليل مشروع Flutter والاستعداد لربط Backend

## نطاق التقرير

يعرض هذا التقرير حالة الملفات التي فُحصت في `mobile/lib` ومراجع Flutter ذات الصلة في مساحة العمل وقت الفحص. لم تُجرَ تغييرات على الكود أثناء الفحص. كانت هناك تغييرات محلية موجودة مسبقًا في مجلد العمل؛ لذلك يصف التقرير الملفات كما كانت موجودة وقت مراجعتها، ولا يفترض أنها مطابقة لآخر نسخة في Git.

لم يظهر مشروع Node.js أو Backend مستقل في جذر مساحة العمل. لذلك لا يتضمن التقرير استنتاجات عن Routes أو Controllers أو Models في Backend غير موجود ضمن الملفات التي أمكن فحصها.

## 1. نظرة معمارية

المشروع تطبيق Flutter مقسّم حسب الميزات:

- `app`: إعداد التطبيق والثيم والتنقل.
- `core`: مكونات مشتركة وبيانات تجريبية.
- `features`: ميزات المصادقة والدورات والحجوزات والمعاهد والطلاب والإدارة والتعريف.

إدارة الحالة مبنية على Provider وChangeNotifier. أغلب التدفقات تمر من الواجهة إلى Controller ثم Service. للحجوزات عقد Repository وتنفيذ تجريبي داخل الذاكرة؛ ولا يوجد تنفيذ متصل بـBackend.

### شجرة `lib` ومسؤولية الملفات

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
    │   ├── routing/admin_shell.dart
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

### مسؤوليات المجلدات والملفات

- `lib/main.dart`: تشغيل التطبيق وتركيب `MultiProvider` لمزوّدي المصادقة والدورات والمعاهد والحجوزات. يُسجّل حاليًا `MockEnrollmentRepository`.
- `lib/app/app.dart`: إنشاء `MaterialApp.router` وتهيئة GoRouter والمسارات وإعادة التوجيه حسب دور المستخدم.
- `lib/app/theme/`: تعريف الألوان والخطوط والمسافات والطباعة والثيم المركزي.
- `lib/core/mock_data/`: بيانات محلية ثابتة أو أولية للمستخدمين والحسابات والدورات والمعاهد والتصنيفات والطلاب.
- `lib/core/widgets/`: أدوات واجهة مشتركة للقائمة الجانبية والهيكل والأزرار والبحث والحقول.
- `lib/features/admin/`: صفحات وهيكل تنقل الإدارة.
- `lib/features/auth/`: نموذج المستخدم ودور الحساب، حالات تسجيل الدخول والتسجيل، خدمة المصادقة ونماذج الواجهة.
- `lib/features/courses/`: نموذج الدورة ومتحكم وخدمة جلب/تحديث بياناتها.
- `lib/features/enrollments/`: دورة حياة الحجز والمدفوعات وإعدادات الحجز وعقد المستودع وتنفيذه التجريبي.
- `lib/features/institutes/`: نموذج المعهد ومتحكم وخدمة وصفحات حساب المعهد.
- `lib/features/onboarding/`: بيانات وشاشة التعريف وزر التنقل بين صفحاتها.
- `lib/features/students/`: صفحات وتجربة الطالب، نموذج الطالب، بطاقات الدورات والمعاهد ومكونات الصفحة الرئيسية.

## 2. الشاشات والواجهات

### جميع الشاشات الموجودة

1. `OnboardingScreen` — صفحات تعريفية.
2. `LoginScreen` — تسجيل الدخول.
3. `RegisterScreen` — إنشاء حساب.
4. `HomeScreen` — الرئيسية للطالب.
5. `CoursesScreen` — قائمة الدورات.
6. `CourseDetailsScreen` — تفاصيل دورة واحدة.
7. `CourseRegistrationScreen` — خطوات التسجيل وإرفاق السند.
8. `BookingsScreen` — حجوزات الطالب.
9. `InstituteDashboardScreen` — لوحة ترحيبية لصاحب المعهد.
10. `InstituteBookingsScreen` — طلبات حجز المعهد.
11. `InstituteCoursesScreen` — واجهة إدارة دورات المعهد.
12. `InstituteStudentsScreen` — واجهة الطلاب المسجلين.
13. `AdminDashboardScreen` — لوحة ترحيبية للإدارة.
14. `AdminInstitutesScreen` — واجهة إدارة المعاهد.
15. `AdminUsersScreen` — واجهة إدارة المستخدمين.
16. `AdminMoreScreen` — واجهة خيارات إضافية.

### حالة الميزات حسب التنفيذ الموجود

| الميزة | الحالة |
|---|---|
| التعريف الأولي | واجهة وتنقل بين الصفحات موجودان؛ لا يظهر تخزين لحالة إكمال التعريف. |
| تسجيل الدخول والتسجيل | متصلان بمسارات Backend؛ JWT محفوظ عبر `flutter_secure_storage`، والجلسة تُستعاد بالتحقق من `/api/auth/me`. |
| الرئيسية للطالب | تعرض دورات ومعاهد وتصنيفات تجريبية؛ البحث والمفضلة والإشعارات غير موصولة بخدمات فعلية. |
| استعراض الدورات والتفاصيل | عرض البيانات والتفاصيل والتنقل للتسجيل موجود، ومصدر البيانات تجريبي. |
| التسجيل والحجوزات | تدفق محلي للتسجيل واختيار نوع الدفعة ومراجعة السند وحالة الحجز موجود؛ لا إرسال إلى خادم ولا رفع للسند. |
| حجوزات المعهد | استعراض وقبول ورفض وإعادة إرسال ضمن المستودع المحلي؛ الحساب يُربط بمعهد من بيانات تجريبية. |
| إدارة دورات المعهد | الشاشة موجودة، لكن لا يظهر تنفيذ تحميل أو إنشاء أو تعديل أو حذف دورات. |
| الطلاب المسجلون | شاشة أولية بلا تحميل بيانات أو منطق إدارة ظاهر. |
| إدارة المنصة | شاشات تنقل وعناوين/محتوى أولي؛ لا يظهر منطق إدارة للمستخدمين أو المعاهد. |
| الملف الشخصي والإعدادات وبقية عناصر القائمة | عناصر ظاهرة، وتعرض رسالة أن الميزة ستكون متاحة لاحقًا. |

### المكونات القابلة لإعادة الاستخدام

- عناصر أساسية: `Button` و`TextFieldApp` و`CustomTextFiledForm` و`Search`.
- هيكل تنقل مشترك: `AppShell` و`AppDrawer`.
- مكونات الطالب: `CourseCard` و`InstituteCard` و`ListCategory` و`FeaturedCoursesCarousel` وأقسام الدورات والمعاهد ورأس الرئيسية.
- مكونات المصادقة: `TopHeader` و`FormLogin` و`FormRegister`.
- مكونات التعريف: `OnBoardingButton`.

وجود عنصر مرئي لا يعني أن وظيفته موصولة: البحث والتصفية والتصنيفات لا تنفذ استعلامًا/تصفية في تدفق الدورات الحالي، وأزرار المفضلة والإشعارات لا تنفذ إجراءات فعلية. في `MostPopularInstitutes` توجد callbacks للعرض الكامل واختيار المعهد، لكن شاشة الرئيسية لا تمررها.

## 3. الثيم ونظام التصميم

- `AppColors`: ألوان مركزية، اللون الأساسي بنفسجي واللون المساعد برتقالي، إضافة إلى ألوان الخلفية والنصوص والحالات.
- `AppFonts`: Cairo للعربية وPoppins للإنجليزية.
- `AppTypography`: أنماط العناوين والنصوص والتسميات.
- `AppSpacing`: قيم موحدة للمسافات والحواف.
- `AppTheme`: ثيم Material 3 وتنسيقات الحقول والأزرار والبطاقات وشريط التنقل والتنبيهات.
- التطبيق يحدد `locale` واللغات المدعومة بالعربية فقط في `app.dart`، رغم تعريف الخط الإنجليزي.

هذا وصف للتصميم الحالي؛ لا يتضمن التقرير اقتراحًا لإعادة تصميم الواجهات.

## 4. إدارة الحالة وتدفق البيانات

نعم، يستخدم المشروع Provider وChangeNotifier:

- `AuthController`: المستخدم الحالي وحالة التحميل ورسائل المصادقة.
- `CourseController`: قائمة الدورات والتحميل والأخطاء وتحديث أعداد المقاعد.
- `InstituteController`: قائمة المعاهد والتحميل والأخطاء.
- `EnrollmentController`: حجوزات الطالب والمعهد والمدفوعات وحالات التحميل والرسائل.

يُنشأ معظمها في `main.dart`. الشاشات تراقب التغييرات عبر `context.watch`، وتستدعي العمليات عبر `context.read`. تمر تفاصيل الدورة إلى الشاشات عبر `GoRouter state.extra`.

### البيانات الوهمية

- `core/mock_data/auth_data.dart`: حسابات تجريبية وكلمات مرور نصية.
- `core/mock_data/users_data.dart`: مستخدم طالب وصاحب معهد ومدير بأدوارهم.
- `core/mock_data/students_data.dart`: طالب ثابت.
- `core/mock_data/courses_data.dart`: دورات وتصنيفات وأسعار وسعات وصور محلية.
- `core/mock_data/institutes_data.dart`: معهد وبيانات مالكه.
- `core/mock_data/categories_data.dart`: قائمة التصنيفات.
- `MockEnrollmentRepository`: الحجوزات والمدفوعات وحالاتها في الذاكرة.

يعرض `README` التجريبي أعلاه أن البيانات تُمحى عند إعادة تشغيل التطبيق، ولا يُرسل API أو دفع إلى خادم، وأن السند مجرد مسار محلي.

## 5. التوجيه والتنقل

يُعرّف GoRouter في `lib/app/app.dart`، والمسارات الحالية:

| المسار | الغرض |
|---|---|
| `/onboarding` | التعريف الأولي، وهو المسار الابتدائي. |
| `/login` | تسجيل الدخول. |
| `/register` | إنشاء الحساب. |
| `/home_screen` | رئيسية الطالب. |
| `/courses_screen` | دورات الطالب. |
| `/bookings_screen` | حجوزات الطالب. |
| `/course-details` | تفاصيل دورة؛ يتطلب `CourseModel` ضمن `extra`. |
| `/course-registration` | التسجيل بدورة؛ يتطلب `CourseModel` ضمن `extra`. |
| `/institute_dashboard` | لوحة المعهد. |
| `/institute_bookings` | حجوزات المعهد. |
| `/institute_courses` | دورات المعهد. |
| `/institute_students` | طلاب المعهد. |
| `/admin_dashboard` | لوحة الإدارة. |
| `/admin_institutes` | إدارة المعاهد. |
| `/admin_users` | إدارة المستخدمين. |
| `/admin_more` | المزيد. |

تستخدم أدوار الطالب والمعهد والإدارة `StatefulShellRoute.indexedStack` مع تبويبات مستقلة. إعادة التوجيه تعتمد على `currentUser.role`: المستخدم غير المسجل يُحوّل إلى الدخول عند طلب مسار محمي، والمستخدم المسجل يُحوّل للمسار الرئيسي لدوره عند دخول مسار عام أو مسار لا يخص دوره.

ملاحظات:

- مسارا تفاصيل الدورة والتسجيل يعيدان المستخدم إلى قائمة الدورات عند غياب `CourseModel` في `extra`؛ لذلك لا يحمل المسار بياناته ذاتيًا كرابط قابل لإعادة الفتح.
- الجلسة لا تُستعاد بعد إعادة تشغيل التطبيق.
- يوجد انتقال إلى قائمة الدورات من `MostPopularCourses` باستخدام `Navigator.push` و`MaterialPageRoute` بدل استخدام GoRouter، أي توجد طريقتان للتنقل.
- لا يظهر مسار مخصص لمعالجة المسارات غير المعروفة.

## 6. Models وControllers وServices وRepositories

### Models

- `UserModel`: معرّف واسم وبريد وهاتف اختياري ودور.
- `StudentModel`: امتداد لنموذج المستخدم.
- `CourseModel`: بيانات الدورة والسعة والمقاعد والسعر والتصنيف والمحتوى.
- `InstituteModel`: بيانات المعهد والمالك وإعدادات الحجز.
- `EnrollmentModel`: بيانات الحجز ومبلغه وحالته ومواعيده ومحاولات الإرسال.
- `PaymentModel`: بيانات الدفعة والسند وحالة المراجعة والرفض.
- `BookingSettingsModel`: مدد المراجعة وإعادة الإرسال وعدد المحاولات الاختياري.
- `OnBoarding`: عنوان ووصف وأيقونة ولون صفحة تعريفية.

لم يظهر في النماذج التشغيلية تحويل JSON (`fromJson`/`toJson`) ضمن الملفات التي فُحصت.

### الطبقات التشغيلية

| الطبقة | ما تنفذه الآن | ما ينقص لربط Backend |
|---|---|---|
| المصادقة | `AuthController` يستخدم `AuthService` وعميل API موحدًا؛ يدعم التسجيل والدخول وGoogle واستعادة الجلسة والخروج المحلي. | لا يوجد مسار إبطال JWT في Backend؛ انتهاء الصلاحية يعالج بإزالة الجلسة محليًا بعد رفض `/me`. |
| الدورات | `CourseController` يستدعي `CourseService` الذي يقرأ بيانات mock ويحدثها في الذاكرة. | قراءة دورات من API، وبقية العمليات حسب نطاق المنتج. |
| المعاهد | `InstituteController` يستدعي `InstituteService` المبني على بيانات mock. | قراءة تفاصيل المعهد وربطها بالمستخدم من Backend. |
| الحجوزات | `EnrollmentController` و`EnrollmentService` يتعاملان مع عقد `EnrollmentRepository`، والتنفيذ المسجل هو mock. | تنفيذ Repository عن بعد ورفع السند ومزامنة تغييرات الحجز والدفع. |
| إدارة المعهد/المنصة | لا تظهر طبقات خدمات أو Controllers متخصصة لهذه الوظائف. | API وطبقات حالة/خدمة إذا كانت وظائف مطلوبة. |

## 7. API والمصادقة ورفع الملفات

- `lib/core/network/api_client.dart` يوحد طلبات `http`، المهلات، ترويسة Bearer، وتحويل أخطاء HTTP/الشبكة إلى رسائل عربية.
- `lib/core/network/token_storage_service.dart` يحفظ JWT باستخدام `flutter_secure_storage`؛ لا يستخدم `SharedPreferences` لحفظه.
- `AuthService` يربط `POST /api/auth/register` و`POST /api/auth/login` و`POST /api/auth/google` و`GET /api/auth/me`.
- `API_BASE_URL` قابل للتهيئة؛ القيمة الافتراضية للمحاكي هي `http://10.0.2.2:5000`.
- Google Sign-In يستخدم API المكتبة 7.x؛ يلزم توفير `GOOGLE_SERVER_CLIENT_ID` كـ`--dart-define`.
- لا يوجد مسار Logout في Backend؛ الخروج الحالي محلي بحذف JWT والبيانات المحفوظة في الذاكرة.
- اختيار السند يستخدم `image_picker`، ثم يحفظ مسار الملف المحلي. لا توجد عملية multipart أو رفع شبكة.
- شاشة المعهد تعرض السند من `File` محلي؛ لا يكون المسار قابلًا للوصول من جهاز آخر.
- الصور المعروضة للدورات والمعاهد تعتمد على `Image.asset` والأصول المحلية في المسارات التي فُحصت.

### احتياجات API المستنتجة من الشاشات الحالية

هذه احتياجات مستنتجة من عمليات الواجهات وليست Endpoints موجودة:

1. تسجيل الدخول والتسجيل وإرجاع المستخدم/الدور/جلسة المصادقة.
2. قراءة قائمة الدورات وتفاصيلها، وقائمة المعاهد وتفاصيلها.
3. رفع صور الدورات والمعاهد إذا كانت الصور تُدار من الخادم.
4. إنشاء حجز لطالب، وقراءة حجوزاته، وقراءة حجوزات المعهد.
5. رفع سند التحويل وإرجاع رابط أو معرف تخزين قابل للوصول.
6. قراءة الدفعات وسجل محاولات الدفع.
7. قبول/رفض دفعة وإرسال سبب الرفض وإعادة إرسال السند.
8. تطبيق قواعد انتهاء المهلة والسعة ومنع الحجوزات المتكررة على الخادم، وليس الاعتماد على تحقق العميل وحده.
9. إدارة الدورات والطلاب والمعاهد والمستخدمين إذا كانت وظائفها مطلوبة ضمن Backend.
10. البحث والتصفية والإشعارات واستعادة كلمة المرور وGoogle Login فقط إذا كانت ضمن نطاق المنتج.

## 8. Backend الموجود في مساحة العمل

يوجد مشروع `Tadreeb-Backend` تحت جذر مساحة العمل. يوفر `/api/auth/register` و`/api/auth/login` و`/api/auth/google` و`/api/auth/me` و`/api/auth/admin-test`. أُكمل `/me` ليعيد بيانات المستخدم الآمنة التي يحتاجها Flutter لاستعادة الجلسة.

## 9. مشكلات وملاحظات الكود ذات الصلة بالربط

1. **تحويل JSON جزئي:** `UserModel` يدعم JSON؛ نماذج الدورات والمعاهد والحجوزات لا تزال بحاجة للتحويل عند ربط تلك الميزات.
2. **بيانات مؤقتة:** خدمات الدورات والمعاهد والحجوزات لا تزال مرتبطة ببيانات محلية/ذاكرة.
3. **السند لا يُرفع:** المسار المحلي لا يمثل ملفًا مخزنًا على الخادم.
4. **بيانات Mock للمصادقة قديمة:** ملفات Mock موجودة في المشروع لكنها غير مستخدمة في مسار `AuthService` الحالي.
5. **قيمة مبلغ إعادة الإرسال:** `EnrollmentService.resubmitPayment` يحسب مبلغًا جديدًا للدفعة، لكن `EnrollmentModel.amountToPay` لا يُحدّث في مسار إعادة الإرسال. تعرض شاشة طلبات المعهد `amountToPay`، لذا قد تعرض مبلغ الطلب الأصلي بدل المبلغ الجديد بعد إعادة الإرسال.
6. **توافق الملفات مع الويب:** استخدامات `dart:io` و`File` و`Image.file` قد لا تلائم Flutter Web دون معالجة خاصة بالمنصة.
7. **وظائف UI غير موصولة:** البحث والتصفية والتصنيفات والمفضلة والإشعارات وبعض عناصر المعهد والإدارة لا تنفذ عمليات بيانات فعلية.
8. **مسارات تعتمد على `extra`:** تفاصيل الدورة والتسجيل لا تملكان مصدر بيانات ذاتيًا عند فتح رابط مباشر.
9. **اختلاف أسلوب التنقل:** يوجد استخدام GoRouter إلى جانب `Navigator.push` اليدوي.
10. **لا يوجد إبطال JWT خادمي:** لا يقدم Backend مسار Logout؛ حذف التوكن محلي ولا يبطل الرمز قبل انتهاء صلاحيته.

## 10. خطة ربط Flutter مع Backend بالترتيب

1. **مكتمل:** توحيد طلبات الشبكة، Base URL للتطوير، أخطاء HTTP والمهلات والترويسات.
2. **مكتمل:** ربط التسجيل والدخول وGoogle و`/me`، وتحويل `UserModel` من JSON.
3. **مكتمل:** حفظ JWT في التخزين الآمن، استعادة الجلسة، حماية مسارات الأدوار، والخروج المحلي.
4. استبدال مصادر بيانات الدورات والمعاهد بخدمات API مع المحافظة على شاشاتها.
5. إنشاء Repository عن بعد للحجوزات وتبديل التنفيذ المسجل في `main.dart`.
6. ربط إنشاء الحجز ومراجعته وإعادة الإرسال، ورفع سند الدفع إلى Backend.
7. ربط إدارة دورات المعهد والطلاب ووظائف الإدارة إذا كانت ضمن نطاق Backend.
8. توفير HTTPS وعنوان إنتاجي، ومطابقة إعداد OAuth بين التطبيق والباك إند.
9. اختبار تدفقات المصادقة على Android مع Backend وOAuth فعليين؛ الاختبارات الحالية تستخدم HTTP mock ولا تثبت نجاح الاتصال الحي.

## 11. الملفات المرتبطة بالتكامل الحالي والمرحلي

- التهيئة والمزوّدات: `lib/main.dart`.
- التنقل وحراسة الأدوار: `lib/app/app.dart`.
- الثيم وإعدادات الاعتماد: `lib/app/theme/` و`pubspec.yaml`.
- المصادقة المنفذة: `lib/features/auth/controllers/auth_controller.dart` و`lib/features/auth/services/auth_service.dart` و`lib/features/auth/models/user_model.dart`، مع `lib/core/network/`.
- استعادة بيانات المستخدم: `Tadreeb-Backend/src/modules/auth/auth.routes.ts` و`Tadreeb-Backend/src/middlewares/auth.middleware.ts`.
- الدورات: `lib/features/courses/controllers/course_controller.dart` و`lib/features/courses/services/course_service.dart` و`lib/features/courses/models/course_model.dart`.
- المعاهد: `lib/features/institutes/controllers/institute_controller.dart` و`lib/features/institutes/services/institute_service.dart` و`lib/features/institutes/models/institute_model.dart`.
- الحجوزات: ملفات `lib/features/enrollments/controllers/` و`services/` و`repositories/` و`models/`.
- التدفقات التي ترسل أو تعرض السند: `lib/features/students/screens/course_registration_screen.dart` و`lib/features/students/screens/bookings_screen.dart` و`lib/features/institutes/screens/institute_bookings_screen.dart`.
- البيانات التجريبية التي ستُستبدل عند اكتمال الربط: `lib/core/mock_data/`.
- وظائف إدارة المعهد والإدارة عند تنفيذها: شاشات `lib/features/institutes/screens/` و`lib/features/admin/screens/`، مع طبقات بيانات مناسبة.

## الخلاصة

المصادقة الآن مرتبطة بباك إند Tadreeb مع تخزين JWT آمن واستعادة الجلسة، بينما ما تزال بيانات الدورات والمعاهد والحجوزات تجريبية. يلزم تهيئة عنوان الإنتاج وOAuth ثم ربط بقية الميزات، مع الحفاظ على تصميم الشاشات الحالي.
