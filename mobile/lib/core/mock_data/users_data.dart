
import '../../features/auth/models/user_model.dart';

const List<UserModel> users = [
  // Institute Owner
  UserModel(
    id: 'user1',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '777000001',
    role: UserRole.instituteOwner,
  ),

  // Student
  UserModel(
    id: 'user2',
    name: 'Jane Smith',
    email: 'jane@example.com',
    phone: '777000002',
    role: UserRole.student,
  ),

  // Platform Admin
  UserModel(
    id: 'user3',
    name: 'Bob Johnson',
    email: 'bob@example.com',
    phone: '777000003',
    role: UserRole.admin,
  ),
];
