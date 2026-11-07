class MockAuthAccount {
  final String userId;
  final String email;
  final String password;

  const MockAuthAccount({
    required this.userId,
    required this.email,
    required this.password,
  });
}

final List<MockAuthAccount> mockAuthAccounts = [
  const MockAuthAccount(
    userId: 'user1',
    email: 'john@example.com',
    password: 'password123',
  ),
  const MockAuthAccount(
    userId: 'user2',
    email: 'jane@example.com',
    password: 'password456',
  ),
  const MockAuthAccount(
    userId: 'user3',
    email: 'bob@example.com',
    password: 'password789',
  ),
];