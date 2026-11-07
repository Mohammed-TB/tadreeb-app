import '../../../core/mock_data/auth_data.dart';
import '../../../core/mock_data/users_data.dart';
import '../models/user_model.dart';

class AuthService {
  final List<UserModel> _users = List.of(users);

  final List<MockAuthAccount> _accounts =
      List.of(mockAuthAccounts);

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // التأكد من أن البريد غير مستخدم
    final exists = _users.any(
      (user) => user.email.toLowerCase() == normalizedEmail,
    );

    if (exists) {
      throw Exception('البريد الإلكتروني مستخدم مسبقًا');
    }

    // إنشاء المستخدم
    final user = UserModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalizedEmail,
    );

    // حفظ بيانات الحساب التجريبية
    final account = MockAuthAccount(
      userId: user.id,
      email: normalizedEmail,
      password: password,
    );

    _users.add(user);
    _accounts.add(account);

    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // البحث عن بيانات الدخول
    final accountIndex = _accounts.indexWhere(
      (account) =>
          account.email.toLowerCase() == normalizedEmail &&
          account.password == password,
    );

    if (accountIndex == -1) {
      throw Exception(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      );
    }

    final account = _accounts[accountIndex];

    // الحصول على بيانات المستخدم
    final userIndex = _users.indexWhere(
      (user) => user.id == account.userId,
    );

    if (userIndex == -1) {
      throw Exception('لم يتم العثور على بيانات المستخدم');
    }

    return _users[userIndex];
  }
}