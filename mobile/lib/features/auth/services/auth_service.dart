import '../models/user_model.dart';

class AuthService {
  final List<UserModel> _users = users;

  Future<UserModel> register(UserModel user) async {
    // التأكد من عدم وجود بريد مسجل مسبقًا
    final exists = _users.any(
          (item) => item.email.toLowerCase() == user.email.toLowerCase(),
    );

    if (exists) {
      throw Exception('البريد الإلكتروني مستخدم مسبقًا');
    }

    _users.add(user);

    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    // البحث عن المستخدم ومطابقة كلمة المرور
    final index = _users.indexWhere(
          (user) =>
      user.email.toLowerCase() == email.toLowerCase() &&
          user.password == password,
    );

    if (index == -1) {
      throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    }

    return _users[index];
  }
}