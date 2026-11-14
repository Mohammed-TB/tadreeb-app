enum AdminUserRole {
  student,
  instituteOwner;

  static AdminUserRole fromJson(Object? value) {
    return switch (value) {
      'student' => AdminUserRole.student,
      'instituteOwner' => AdminUserRole.instituteOwner,
      _ => throw const FormatException('Invalid user role in admin response'),
    };
  }

  String get label => switch (this) {
    AdminUserRole.student => 'متدرب',
    AdminUserRole.instituteOwner => 'صاحب معهد',
  };
}

enum AdminUserStatus {
  active,
  pending,
  suspended;

  static AdminUserStatus fromJson(Object? value) {
    return AdminUserStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw const FormatException(
        'Invalid user status in admin response',
      ),
    );
  }

  String get label => switch (this) {
    AdminUserStatus.active => 'نشط',
    AdminUserStatus.pending => 'معلق',
    AdminUserStatus.suspended => 'موقوف',
  };
}

class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final AdminUserRole role;
  final AdminUserStatus status;
  final DateTime createdAt;

  AdminUserModel copyWith({AdminUserStatus? status}) {
    return AdminUserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final email = json['email'];
    final createdAtValue = json['createdAt'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;

    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        email is! String ||
        email.trim().isEmpty ||
        createdAt == null) {
      throw const FormatException('Invalid user in admin response');
    }

    return AdminUserModel(
      id: id,
      name: name,
      email: email,
      role: AdminUserRole.fromJson(json['role']),
      status: AdminUserStatus.fromJson(json['status']),
      createdAt: createdAt,
    );
  }
}

class AdminUserPage {
  const AdminUserPage({
    required this.users,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<AdminUserModel> users;
  final int total;
  final int page;
  final int totalPages;

  factory AdminUserPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid user list response');
    }

    final usersJson = data['users'];
    final pagination = data['pagination'];
    if (usersJson is! List || pagination is! Map<String, dynamic>) {
      throw const FormatException('Invalid user list response');
    }

    return AdminUserPage(
      users: usersJson
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid user list item');
            }
            return AdminUserModel.fromJson(item);
          })
          .toList(growable: false),
      total: _readPaginationInt(pagination['total'], 'pagination.total'),
      page: _readPaginationInt(pagination['page'], 'pagination.page'),
      totalPages: _readPaginationInt(
        pagination['totalPages'],
        'pagination.totalPages',
      ),
    );
  }
}

int _readPaginationInt(Object? value, String field) {
  if (value is num && value.isFinite && value >= 0) return value.toInt();
  throw FormatException('Invalid user list field: $field');
}
