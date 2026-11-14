enum AdminInstituteStatus {
  active,
  pending,
  suspended;

  static AdminInstituteStatus fromJson(Object? value) {
    return AdminInstituteStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw const FormatException(
        'Invalid institute status in admin response',
      ),
    );
  }

  String get label {
    switch (this) {
      case AdminInstituteStatus.active:
        return 'نشط';
      case AdminInstituteStatus.pending:
        return 'معلق';
      case AdminInstituteStatus.suspended:
        return 'موقوف';
    }
  }
}

class AdminInstituteModel {
  const AdminInstituteModel({
    required this.name,
    required this.status,
    required this.createdAt,
  });

  final String name;
  final AdminInstituteStatus status;
  final DateTime createdAt;

  factory AdminInstituteModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final createdAtValue = json['createdAt'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;

    if (name is! String || name.trim().isEmpty || createdAt == null) {
      throw const FormatException('Invalid institute in admin response');
    }

    return AdminInstituteModel(
      name: name,
      status: AdminInstituteStatus.fromJson(json['status']),
      createdAt: createdAt,
    );
  }
}

class AdminInstitutePage {
  const AdminInstitutePage({
    required this.institutes,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<AdminInstituteModel> institutes;
  final int total;
  final int page;
  final int totalPages;

  factory AdminInstitutePage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid institute list response');
    }

    final institutesJson = data['institutes'];
    final pagination = data['pagination'];
    if (institutesJson is! List || pagination is! Map<String, dynamic>) {
      throw const FormatException('Invalid institute list response');
    }

    return AdminInstitutePage(
      institutes: institutesJson
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid institute list item');
            }
            return AdminInstituteModel.fromJson(item);
          })
          .toList(growable: false),
      total: _readInt(pagination['total'], 'pagination.total'),
      page: _readInt(pagination['page'], 'pagination.page'),
      totalPages: _readInt(pagination['totalPages'], 'pagination.totalPages'),
    );
  }
}

int _readInt(Object? value, String field) {
  if (value is num && value.isFinite && value >= 0) return value.toInt();
  throw FormatException('Invalid institute list field: $field');
}
