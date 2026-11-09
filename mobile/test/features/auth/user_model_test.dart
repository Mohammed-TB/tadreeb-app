import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/auth/models/user_model.dart';

void main() {
  test('parses backend user fields and serializes the same field names', () {
    final user = UserModel.fromJson({
      'id': 'user-1',
      'name': 'Student',
      'email': 'student@example.com',
      'phone': '777000000',
      'role': 'student',
      'status': 'active',
      'authProvider': 'local',
    });

    expect(user.role, UserRole.student);
    expect(user.status, 'active');
    expect(user.authProvider, 'local');
    expect(user.toJson()['id'], 'user-1');
    expect(user.toJson()['authProvider'], 'local');
  });

  test('accepts MongoDB and middleware user ID field aliases', () {
    expect(
      UserModel.fromJson({
        '_id': 'mongo-id',
        'name': 'Student',
        'email': 'student@example.com',
        'role': 'student',
      }).id,
      'mongo-id',
    );
    expect(
      UserModel.fromJson({
        'userId': 'middleware-id',
        'name': 'Student',
        'email': 'student@example.com',
        'role': 'student',
      }).id,
      'middleware-id',
    );
  });
}
