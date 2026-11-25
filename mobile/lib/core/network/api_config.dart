
class ApiConfig {
  // يتغير العنوان حسب بيئة التشغيل من خلال dart-define.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tadreeb-backend.onrender.com',
  );
}
