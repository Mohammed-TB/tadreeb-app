
class ApiConfig {
  // يتغير العنوان حسب بيئة التشغيل من خلال dart-define.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tadreeb-backend-pr-1.onrender.com',

    // defaultValue: 'https://tadreeb-backend.onrender.com',
    // defaultValue: 'http://127.0.0.1:5000',

    
  );
}
