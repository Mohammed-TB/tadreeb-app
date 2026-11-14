enum InstituteDashboardReservationStatus {
  pendingPayment,
  paymentSubmitted,
  confirmed,
  rejected,
  expired,
  cancelled;

  static InstituteDashboardReservationStatus fromJson(Object? value) {
    return InstituteDashboardReservationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw const FormatException(
        'Invalid reservation status in institute dashboard',
      ),
    );
  }

  String get label => switch (this) {
    InstituteDashboardReservationStatus.pendingPayment => 'بانتظار الدفع',
    InstituteDashboardReservationStatus.paymentSubmitted => 'قيد المراجعة',
    InstituteDashboardReservationStatus.confirmed => 'مؤكد',
    InstituteDashboardReservationStatus.rejected => 'مرفوض',
    InstituteDashboardReservationStatus.expired => 'منتهي',
    InstituteDashboardReservationStatus.cancelled => 'ملغي',
  };
}

class InstituteDashboardData {
  const InstituteDashboardData({
    required this.instituteName,
    required this.summary,
    required this.courseOccupancy,
    required this.recentReservations,
    required this.alerts,
  });

  final String instituteName;
  final InstituteDashboardSummary summary;
  final List<InstituteDashboardCourse> courseOccupancy;
  final List<InstituteDashboardReservation> recentReservations;
  final InstituteDashboardAlerts alerts;

  factory InstituteDashboardData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data'], 'data');
    final institute = _asMap(data['institute'], 'institute');
    final summary = _asMap(data['summary'], 'summary');
    final courses = data['courseOccupancy'];
    final reservations = data['recentReservations'];
    if (courses is! List || reservations is! List) {
      throw const FormatException('Invalid institute dashboard lists');
    }

    final name = institute['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Invalid institute name in dashboard');
    }

    return InstituteDashboardData(
      instituteName: name,
      summary: InstituteDashboardSummary.fromJson(summary),
      courseOccupancy: courses
          .map(
            (item) => InstituteDashboardCourse.fromJson(
              _asMap(item, 'courseOccupancy[]'),
            ),
          )
          .toList(growable: false),
      recentReservations: reservations
          .map(
            (item) => InstituteDashboardReservation.fromJson(
              _asMap(item, 'recentReservations[]'),
            ),
          )
          .toList(growable: false),
      alerts: InstituteDashboardAlerts.fromJson(
        _asMap(data['alerts'], 'alerts'),
      ),
    );
  }
}

class InstituteDashboardSummary {
  const InstituteDashboardSummary({
    required this.totalCourses,
    required this.publishedCourses,
    required this.totalReservations,
    required this.reservationsThisMonth,
    required this.confirmedThisMonth,
    required this.pendingPaymentThisMonth,
    required this.paymentSubmittedThisMonth,
    required this.rejectedThisMonth,
    required this.expiredThisMonth,
    required this.cancelledThisMonth,
    required this.receiptsToReview,
    required this.totalRevenue,
    required this.monthlyRevenue,
  });

  final int totalCourses;
  final int publishedCourses;
  final int totalReservations;
  final int reservationsThisMonth;
  final int confirmedThisMonth;
  final int pendingPaymentThisMonth;
  final int paymentSubmittedThisMonth;
  final int rejectedThisMonth;
  final int expiredThisMonth;
  final int cancelledThisMonth;
  final int receiptsToReview;
  final double totalRevenue;
  final List<InstituteDashboardMonthlyRevenue> monthlyRevenue;

  factory InstituteDashboardSummary.fromJson(Map<String, dynamic> json) {
    final courses = _asMap(json['courses'], 'summary.courses');
    final reservations = _asMap(
      json['reservations'],
      'summary.reservations',
    );
    final revenue = _asMap(json['revenue'], 'summary.revenue');
    final monthlyJson = revenue['monthly'];
    if (monthlyJson is! List) {
      throw const FormatException('Invalid monthly revenue data');
    }

    return InstituteDashboardSummary(
      totalCourses: _asInt(courses['total'], 'courses.total'),
      publishedCourses: _asInt(courses['published'], 'courses.published'),
      totalReservations: _asInt(reservations['total'], 'reservations.total'),
      reservationsThisMonth: _asInt(
        reservations['thisMonth'],
        'reservations.thisMonth',
      ),
      confirmedThisMonth: _asInt(
        reservations['confirmedThisMonth'],
        'reservations.confirmedThisMonth',
      ),
      pendingPaymentThisMonth: _asInt(
        reservations['pendingPaymentThisMonth'],
        'reservations.pendingPaymentThisMonth',
      ),
      paymentSubmittedThisMonth: _asInt(
        reservations['paymentSubmittedThisMonth'],
        'reservations.paymentSubmittedThisMonth',
      ),
      rejectedThisMonth: _asInt(
        reservations['rejectedThisMonth'],
        'reservations.rejectedThisMonth',
      ),
      expiredThisMonth: _asInt(
        reservations['expiredThisMonth'],
        'reservations.expiredThisMonth',
      ),
      cancelledThisMonth: _asInt(
        reservations['cancelledThisMonth'],
        'reservations.cancelledThisMonth',
      ),
      receiptsToReview: _asInt(
        reservations['receiptsToReview'],
        'reservations.receiptsToReview',
      ),
      totalRevenue: _asDouble(revenue['total'], 'revenue.total'),
      monthlyRevenue: monthlyJson
          .map(
            (item) => InstituteDashboardMonthlyRevenue.fromJson(
              _asMap(item, 'revenue.monthly[]'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class InstituteDashboardMonthlyRevenue {
  const InstituteDashboardMonthlyRevenue({
    required this.year,
    required this.month,
    required this.revenue,
  });

  final int year;
  final int month;
  final double revenue;

  factory InstituteDashboardMonthlyRevenue.fromJson(
    Map<String, dynamic> json,
  ) {
    final month = _asInt(json['month'], 'revenue.month');
    if (month < 1 || month > 12) {
      throw const FormatException('Invalid month in revenue data');
    }
    return InstituteDashboardMonthlyRevenue(
      year: _asInt(json['year'], 'revenue.year'),
      month: month,
      revenue: _asDouble(json['revenue'], 'revenue.amount'),
    );
  }
}

class InstituteDashboardCourse {
  const InstituteDashboardCourse({
    required this.id,
    required this.title,
    required this.occupied,
    required this.capacity,
  });

  final String id;
  final String title;
  final int occupied;
  final int capacity;

  factory InstituteDashboardCourse.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      throw const FormatException('Invalid course occupancy item');
    }
    return InstituteDashboardCourse(
      id: id,
      title: title,
      occupied: _asInt(json['occupied'], 'course.occupied'),
      capacity: _asInt(json['capacity'], 'course.capacity'),
    );
  }
}

class InstituteDashboardReservation {
  const InstituteDashboardReservation({
    required this.id,
    required this.studentName,
    required this.courseTitle,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String studentName;
  final String courseTitle;
  final InstituteDashboardReservationStatus status;
  final DateTime createdAt;

  factory InstituteDashboardReservation.fromJson(
    Map<String, dynamic> json,
  ) {
    final id = json['id'];
    final studentName = json['studentName'];
    final courseTitle = json['courseTitle'];
    final createdAtValue = json['createdAt'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;

    if (id is! String ||
        id.isEmpty ||
        studentName is! String ||
        studentName.isEmpty ||
        courseTitle is! String ||
        createdAt == null) {
      throw const FormatException('Invalid recent reservation item');
    }

    return InstituteDashboardReservation(
      id: id,
      studentName: studentName,
      courseTitle: courseTitle,
      status: InstituteDashboardReservationStatus.fromJson(json['status']),
      createdAt: createdAt,
    );
  }
}

class InstituteDashboardAlerts {
  const InstituteDashboardAlerts({
    required this.coursesStartingSoon,
    required this.fullCourses,
  });

  final int coursesStartingSoon;
  final int fullCourses;

  factory InstituteDashboardAlerts.fromJson(Map<String, dynamic> json) {
    return InstituteDashboardAlerts(
      coursesStartingSoon: _asInt(
        json['coursesStartingSoon'],
        'alerts.coursesStartingSoon',
      ),
      fullCourses: _asInt(json['fullCourses'], 'alerts.fullCourses'),
    );
  }
}

Map<String, dynamic> _asMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Invalid institute dashboard field: $field');
}

int _asInt(Object? value, String field) {
  if (value is num && value.isFinite && value >= 0) return value.toInt();
  throw FormatException('Invalid institute dashboard field: $field');
}

double _asDouble(Object? value, String field) {
  if (value is num && value.isFinite && value >= 0) return value.toDouble();
  throw FormatException('Invalid institute dashboard field: $field');
}
