
class ApiConfig {
  // يتغير العنوان حسب بيئة التشغيل من خلال dart-define.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );
}
