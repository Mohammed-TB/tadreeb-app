class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });
  final String id;
  final String name;
  final String email;
  final String password;
}

List<UserModel> users = [
  UserModel(
    id: 'user1',
    name: 'John Doe',
    email: 'john@example.com',
    password: 'password123',
  ),
  UserModel(
    id: 'user2',
    name: 'Jane Smith',
    email: 'jane@example.com',
    password: 'password456',
  ),
  UserModel(
    id: 'user3',
    name: 'Bob Johnson',
    email: 'bob@example.com',
    password: 'password789',
  ),
];
