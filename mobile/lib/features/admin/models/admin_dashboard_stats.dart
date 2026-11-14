class AdminDashboardStats {
  const AdminDashboardStats({
    required this.users,
    required this.institutes,
    required this.courses,
    required this.reservations,
    required this.revenue,
  });

  final AdminUserStats users;
  final AdminInstituteStats institutes;
  final AdminCourseStats courses;
  final AdminReservationStats reservations;
  final AdminRevenueStats revenue;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data'], 'data');
    return AdminDashboardStats(
      users: AdminUserStats.fromJson(_asMap(data['users'], 'users')),
      institutes: AdminInstituteStats.fromJson(
        _asMap(data['institutes'], 'institutes'),
      ),
      courses: AdminCourseStats.fromJson(_asMap(data['courses'], 'courses')),
      reservations: AdminReservationStats.fromJson(
        _asMap(data['reservations'], 'reservations'),
      ),
      revenue: AdminRevenueStats.fromJson(_asMap(data['revenue'], 'revenue')),
    );
  }
}

class AdminUserStats {
  const AdminUserStats({
    required this.total,
    required this.students,
    required this.instituteOwners,
    required this.active,
    required this.newLast30Days,
  });

  final int total;
  final int students;
  final int instituteOwners;
  final int active;
  final int newLast30Days;

  factory AdminUserStats.fromJson(Map<String, dynamic> json) {
    return AdminUserStats(
      total: _asInt(json['total'], 'users.total'),
      students: _asInt(json['students'], 'users.students'),
      instituteOwners: _asInt(json['instituteOwners'], 'users.instituteOwners'),
      active: _asInt(json['active'], 'users.active'),
      newLast30Days: _asInt(json['newLast30Days'], 'users.newLast30Days'),
    );
  }
}

class AdminInstituteStats {
  const AdminInstituteStats({
    required this.total,
    required this.active,
    required this.pending,
    required this.suspended,
  });

  final int total;
  final int active;
  final int pending;
  final int suspended;

  factory AdminInstituteStats.fromJson(Map<String, dynamic> json) {
    return AdminInstituteStats(
      total: _asInt(json['total'], 'institutes.total'),
      active: _asInt(json['active'], 'institutes.active'),
      pending: _asInt(json['pending'], 'institutes.pending'),
      suspended: _asInt(json['suspended'], 'institutes.suspended'),
    );
  }
}

class AdminCourseStats {
  const AdminCourseStats({required this.total, required this.published});

  final int total;
  final int published;

  factory AdminCourseStats.fromJson(Map<String, dynamic> json) {
    return AdminCourseStats(
      total: _asInt(json['total'], 'courses.total'),
      published: _asInt(json['published'], 'courses.published'),
    );
  }
}

class AdminReservationStats {
  const AdminReservationStats({
    required this.total,
    required this.confirmed,
    required this.pendingPayment,
    required this.paymentSubmitted,
    required this.rejected,
    required this.cancelled,
    required this.expired,
    required this.newLast30Days,
  });

  final int total;
  final int confirmed;
  final int pendingPayment;
  final int paymentSubmitted;
  final int rejected;
  final int cancelled;
  final int expired;
  final int newLast30Days;

  int get pending => pendingPayment + paymentSubmitted;
  int get closed => cancelled + expired;

  factory AdminReservationStats.fromJson(Map<String, dynamic> json) {
    return AdminReservationStats(
      total: _asInt(json['total'], 'reservations.total'),
      confirmed: _asInt(json['confirmed'], 'reservations.confirmed'),
      pendingPayment: _asInt(
        json['pendingPayment'],
        'reservations.pendingPayment',
      ),
      paymentSubmitted: _asInt(
        json['paymentSubmitted'],
        'reservations.paymentSubmitted',
      ),
      rejected: _asInt(json['rejected'], 'reservations.rejected'),
      cancelled: _asInt(json['cancelled'], 'reservations.cancelled'),
      expired: _asInt(json['expired'], 'reservations.expired'),
      newLast30Days: _asInt(
        json['newLast30Days'],
        'reservations.newLast30Days',
      ),
    );
  }
}

class AdminRevenueStats {
  const AdminRevenueStats({required this.total, required this.monthly});

  final double total;
  final List<AdminMonthlyRevenue> monthly;

  factory AdminRevenueStats.fromJson(Map<String, dynamic> json) {
    final monthlyJson = json['monthly'];
    if (monthlyJson is! List) {
      throw const FormatException('Invalid admin revenue monthly data');
    }

    return AdminRevenueStats(
      total: _asDouble(json['total'], 'revenue.total'),
      monthly: monthlyJson
          .map(
            (entry) => AdminMonthlyRevenue.fromJson(
              _asMap(entry, 'revenue.monthly[]'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class AdminMonthlyRevenue {
  const AdminMonthlyRevenue({
    required this.year,
    required this.month,
    required this.revenue,
    required this.count,
  });

  final int year;
  final int month;
  final double revenue;
  final int count;

  factory AdminMonthlyRevenue.fromJson(Map<String, dynamic> json) {
    final date = _asMap(json['_id'], 'revenue.monthly._id');
    final month = _asInt(date['month'], 'revenue.monthly._id.month');
    if (month < 1 || month > 12) {
      throw const FormatException('Invalid month in admin revenue data');
    }
    return AdminMonthlyRevenue(
      year: _asInt(date['year'], 'revenue.monthly._id.year'),
      month: month,
      revenue: _asDouble(json['revenue'], 'revenue.monthly.revenue'),
      count: _asInt(json['count'], 'revenue.monthly.count'),
    );
  }
}

Map<String, dynamic> _asMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Invalid admin dashboard field: $field');
}

int _asInt(Object? value, String field) {
  if (value is num && value.isFinite) return value.toInt();
  throw FormatException('Invalid admin dashboard field: $field');
}

double _asDouble(Object? value, String field) {
  if (value is num && value.isFinite) return value.toDouble();
  throw FormatException('Invalid admin dashboard field: $field');
}
