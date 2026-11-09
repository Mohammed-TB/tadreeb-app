# تقرير تنفيذ وربط نظام المصادقة في Tadreeb

## 1. ملخص التنفيذ

تم استبدال تسجيل الدخول والتسجيل التجريبي في Flutter بتكامل مع مسارات المصادقة الموجودة في Backend. أضيف عميل HTTP موحد، ومعالجة موحدة للأخطاء والمهلات، وتخزين آمن لـJWT واستعادة الجلسة عبر `/me`. رُبط Google Sign-In باستخدام API الإصدار 7.x، مع الإبقاء على تصميم الشاشات وProvider وGoRouter.

لم تُحذف بيانات Mock من المشروع؛ خدمات الدورات والمعاهد والحجوزات ما زالت تجريبية ولا يشملها هذا التكامل. لم يُضف endpoint لتسجيل الخروج في Backend، ويجري الخروج الحالي بمسح Token وحالة المستخدم محليًا.

## 2. الملفات التي فُحصت

### Flutter

- `mobile/lib/features/auth/`: المتحكم والخدمة والنموذج والشاشات والنماذج الفرعية.
- `mobile/lib/core/`: أدوات الواجهة وبيانات Mock ومكان طبقة الشبكة والتخزين.
- `mobile/lib/main.dart`: تسجيل Providers.
- `mobile/lib/app/app.dart`: GoRouter والتوجيه بحسب الدور.
- `mobile/pubspec.yaml` و`mobile/pubspec.lock`: إصدارات `http` و`flutter_secure_storage` و`google_sign_in`.
- `mobile/android/app/src/main/AndroidManifest.xml` وإعدادات Android ذات الصلة.
- `mobile/ios/Runner/Info.plist`.
- اختبارات Flutter الموجودة والاختبارات المرتبطة بالمصادقة.

### Backend

- `Tadreeb-Backend/src/modules/auth/auth.routes.ts`
- `Tadreeb-Backend/src/modules/auth/auth.controller.ts`
- `Tadreeb-Backend/src/modules/auth/auth.service.ts`
- `Tadreeb-Backend/src/modules/auth/auth.validation.ts`
- `Tadreeb-Backend/src/modules/auth/auth.types.ts`
- `Tadreeb-Backend/src/modules/users/user.model.ts`
- `Tadreeb-Backend/src/middlewares/auth.middleware.ts`
- `Tadreeb-Backend/src/app.ts` و`Tadreeb-Backend/src/server.ts`
- `Tadreeb-Backend/package.json` و`Tadreeb-Backend/tsconfig.json`

لم تُقرأ قيم ملفات البيئة ولم تُدرج أي بيانات اعتماد أو أسرار في هذا التقرير.

## 3. الملفات التي أُنشئت

- `mobile/lib/core/network/api_client.dart`: عميل HTTP، عناوين API، مهلات، Bearer Token ومعالجة الاستجابة.
- `mobile/lib/core/network/api_exception.dart`: خطأ API موحد ورسائله.
- `mobile/lib/core/network/token_storage_service.dart`: تخزين JWT الآمن.
- `mobile/test/core/network/api_client_test.dart`: اختبارات طلبات الشبكة والأخطاء.
- `mobile/test/features/auth/user_model_test.dart`: اختبارات تحليل وتحويل المستخدم.
- `mobile/test/features/auth/auth_service_test.dart`: اختبارات التسجيل واستعادة الجلسة باستعمال HTTP mock.

## 4. الملفات التي عُدّلت

### Flutter

- `mobile/lib/main.dart`: تسجيل خدمات التخزين والشبكة والمصادقة وبدء استعادة الجلسة.
- `mobile/lib/app/app.dart`: تأجيل التوجيه حتى اكتمال استعادة الجلسة مع إبقاء التوجيه حسب الدور.
- `mobile/lib/features/auth/controllers/auth_controller.dart`: حالات التحميل والخطأ والدخول والتسجيل وGoogle واستعادة الجلسة والخروج.
- `mobile/lib/features/auth/services/auth_service.dart`: ربط عمليات المصادقة بالـBackend وGoogle.
- `mobile/lib/features/auth/models/user_model.dart`: إضافة `fromJson` و`toJson` ودعم `status` و`authProvider`.
- `mobile/lib/features/auth/screens/login_screen.dart` و`register_screen.dart`: ربط الدخول والتسجيل وGoogle وتوجيه المستخدم بحسب الدور.
- `mobile/lib/features/auth/widgets/form_login.dart` و`form_register.dart`: ربط أزرار Google دون تغيير شكل الواجهة.
- `mobile/lib/core/widgets/app_drawer.dart`: مسح الجلسة محليًا عند الخروج وإظهار الخطأ إن تعذر حذف Token.
- `mobile/android/app/src/debug/AndroidManifest.xml` و`mobile/android/app/src/profile/AndroidManifest.xml`: السماح باتصال HTTP المحلي لبيئات التطوير فقط.
- `mobile/README.md`: تحديث وصف المصادقة وتعليمات إعداد API وGoogle.
- `mobile/test/features/institutes/institute_bookings_screen_test.dart` و`mobile/test/features/students/course_registration_screen_test.dart`: جعل اختبارات الواجهات تستخدم AuthService تجريبيًا بدل الشبكة.

### Backend

- `Tadreeb-Backend/src/middlewares/auth.middleware.ts`: جلب حقول المستخدم الآمنة وإتاحتها للطلب بعد التحقق من JWT.
- `Tadreeb-Backend/src/modules/auth/auth.routes.ts`: توحيد `GET /api/auth/me` لإرجاع ملف مستخدم كامل مناسب للاستعادة.

كانت في مساحة العمل تغييرات وملفات غير متتبعة قبل تنفيذ المهمة. لم تُرجع أو تُحذف التغييرات غير المرتبطة بالمهمة.

## 5. المسارات المرتبطة

المسارات المستخدمة من Backend:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/google`
- `GET /api/auth/me`

لا يوجد مسار Logout في Backend؛ لم تتم إضافة مسار جديد.

## 6. شكل Requests وResponses المستخدم فعليًا

### تسجيل طالب بالبريد وكلمة المرور

```json
{
  "name": "اسم الطالب",
  "email": "student@example.com",
  "password": "..."
}
```

### تسجيل الدخول بالبريد وكلمة المرور

```json
{
  "email": "student@example.com",
  "password": "..."
}
```

### تسجيل الدخول عبر Google

```json
{
  "idToken": "<Google ID Token>"
}
```

### استجابة التسجيل والدخول وGoogle

الخدمة الخلفية تعيد الاستجابة بهذا الشكل:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "<user id>",
      "name": "اسم المستخدم",
      "email": "user@example.com",
      "role": "student",
      "status": "active"
    },
    "token": "<Tadreeb JWT>"
  }
}
```

`phone` و`authProvider` حقول اختيارية في نموذج Flutter لأن استجابة الدخول والتسجيل الحالية من Backend لا تتضمنهما.

### طلب المستخدم الحالي

```http
GET /api/auth/me
Authorization: Bearer <Tadreeb JWT>
```

والاستجابة التي يعيدها Backend بعد التعديل:

```json
{
  "success": true,
  "message": "Authenticated successfully",
  "user": {
    "id": "<user id>",
    "name": "اسم المستخدم",
    "email": "user@example.com",
    "phone": "اختياري",
    "role": "student",
    "status": "active",
    "authProvider": "local"
  }
}
```

## 7. Base URL ومعالجة الأخطاء

- الافتراضي مخصص لمحاكي Android: `http://10.0.2.2:5000`.
- يمكن تحديد عنوان مختلف وقت التشغيل عبر `--dart-define=API_BASE_URL=...`.
- تُستخدم مهلة اتصال مقدارها 15 ثانية.
- تُعالج أخطاء HTTP، وانقطاع الشبكة، والمهلة، والاستجابة غير الصالحة برسائل عربية.
- ترويسة Bearer تُضاف للطلبات الموثقة فقط.
- أُضيف السماح بـHTTP إلى manifests الخاصة بـdebug وprofile للتطوير المحلي؛ ينبغي استخدام HTTPS في الإنتاج.

## 8. تخزين واستعادة Token

- يستخدم `TokenStorageService` مكتبة `flutter_secure_storage` لحفظ JWT؛ لا يُحفظ Token في SharedPreferences.
- بعد نجاح التسجيل أو الدخول أو Google، يُحفظ JWT الصادر عن Tadreeb في التخزين الآمن.
- عند بدء التطبيق، يقرأ المتحكم Token ثم يستدعي `/api/auth/me` للتحقق من صلاحيته واستعادة المستخدم.
- إذا رفض الخادم الجلسة برمز 401 أو 403، تُمسح محليًا.
- عند Logout، يُمسح المستخدم من حالة التطبيق ويمسح JWT من التخزين الآمن. هذا لا يبطل JWT على الخادم قبل انتهاء صلاحيته.

## 9. Google Sign-In

يستخدم التنفيذ الواجهة الحديثة للإصدار `google_sign_in 7.2.0`: `GoogleSignIn.instance`, و`initialize`, و`authenticate`, و`account.authentication.idToken`. يرسل ID Token إلى `/api/auth/google`.

يتطلب التشغيل تحديد Web OAuth Client ID عبر:

```shell
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID
```

يجب أن يطابق هذا المعرّف جمهور Google المضبوط في Backend. لم يُختبر تسجيل Google مع OAuth حي.

## 10. نتائج الاختبارات والتحقق

- `flutter analyze`: نجح دون مشاكل.
- `flutter test`: نجحت مجموعة الاختبارات كاملة، **26 اختبارًا**.
- `npm run typecheck` داخل `Tadreeb-Backend`: نجح.
- `flutter build apk --debug`: نجح، بما في ذلك مهمة `:app:assembleDebug`.
- `git diff --check`: نجح؛ ظهر تحذير line endings من Git لملف `app.dart`.
- فحص `http://localhost:5000/api/health`: لم يستطع الاتصال لأن Backend لم يكن يعمل/متاحًا في بيئة التنفيذ.

اختبارات AuthService تستخدم HTTP mock؛ لذلك لا تدّعي نجاح اتصال حي أو تسجيل حقيقي بقاعدة البيانات.

## 11. الإعدادات اليدوية المتبقية

1. تشغيل Backend وإتاحة عنوانه للجهاز أو المحاكي، وتحديد `API_BASE_URL` المناسب إن لم يكن محاكي Android.
2. تحديد `GOOGLE_SERVER_CLIENT_ID` كـdart-define ومطابقة إعدادات OAuth مع package `com.tadreeb.app` وشهادة توقيع البناء.
3. استخدام HTTPS وعنوان إنتاجي عند إصدار التطبيق.
4. التأكد من وجود حساب صاحب المعهد بالدور الصحيح في قاعدة البيانات؛ التسجيل الحالي في Backend ينشئ طالبًا.

## 12. القيود والمشكلات المتبقية

- لم يتم اختبار المسارات على Backend حي لأن الخادم لم يكن متاحًا أثناء التحقق.
- لم يُختبر OAuth الفعلي أو إعداد حسابات Google على جهاز Android.
- لا يوجد إبطال خادمي للجلسة أو endpoint Logout، والخروج الحالي محلي فقط.
- البيانات الخاصة بالدورات والمعاهد والحجوزات ما تزال Mock وغير مشمولة بهذه المهمة.
- لم تُضف آلية تجديد JWT؛ عند انتهاء الصلاحية يرفض `/me` الجلسة وتُزال محليًا.

## الخلاصة

اكتمل مسار المصادقة في Flutter مع Backend من حيث تنفيذ الطلبات، تحليل بيانات المستخدم، حفظ Token آمنًا، استعادة الجلسة، Google Sign-In وفق API 7.x، وتوجيه الأدوار. اجتازت التحليلات والاختبارات والبناء، بينما يبقى التحقق الحي مرهونًا بتشغيل Backend وضبط OAuth وعنوان البيئة.
