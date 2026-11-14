/// نموذج حجز الطالب المسترجع من الـ API (GET /api/reservations/my)
class StudentReservationModel {
  final String id;
  final String courseId;
  final String courseTitle;
  final String? courseImage;
  final double coursePrice;
  final double courseDeposit;
  final String? courseLocation;
  final DateTime? courseStartDate;
  final DateTime? courseEndDate;

  final String instituteId;
  final String instituteName;
  final String? instituteLogo;
  final String? instituteAddress;

  final String studentName;
  final String studentPhone;
  final String bookingType; // online | inPerson
  final String paymentOption; // full | deposit
  final double totalAmount;
  final double amountToPay;
  final double amountPaid;
  final String paymentStatus; // unpaid | partial | paid
  final String status; // pendingPayment | paymentSubmitted | confirmed | rejected | expired | cancelled

  final String? receiptPublicId;
  final String? receiptUrl;
  final String? rejectionReason;
  final DateTime? receiptResubmissionDeadline;
  final DateTime? expiresAt;
  final String attendanceStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentReservationModel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    this.courseImage,
    required this.coursePrice,
    required this.courseDeposit,
    this.courseLocation,
    this.courseStartDate,
    this.courseEndDate,
    required this.instituteId,
    required this.instituteName,
    this.instituteLogo,
    this.instituteAddress,
    required this.studentName,
    required this.studentPhone,
    required this.bookingType,
    required this.paymentOption,
    required this.totalAmount,
    required this.amountToPay,
    required this.amountPaid,
    required this.paymentStatus,
    required this.status,
    this.receiptPublicId,
    this.receiptUrl,
    this.rejectionReason,
    this.receiptResubmissionDeadline,
    this.expiresAt,
    this.attendanceStatus = 'notMarked',
    required this.createdAt,
    required this.updatedAt,
  });

  String get normalizedStatus => status.replaceAll('_', '').toLowerCase();

  String get statusLabel {
    switch (normalizedStatus) {
      case 'pendingpayment':
        return 'بانتظار السداد';
      case 'paymentsubmitted':
        return 'قيد المراجعة';
      case 'confirmed':
        return 'مؤكد ومقبول';
      case 'rejected':
        return 'سند مرفوض';
      case 'expired':
        return 'منتهي الصلاحية';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String get paymentOptionLabel {
    final opt = paymentOption.toLowerCase();
    if (opt == 'deposit') return 'عربون الحجز';
    if (opt == 'full') return 'كامل الرسوم';
    return paymentOption;
  }

  String get paymentStatusLabel {
    final p = paymentStatus.toLowerCase();
    switch (p) {
      case 'paid':
        return 'مدفوع بالكامل';
      case 'partial':
        return 'مدفوع جزئياً (عربون)';
      case 'unpaid':
        return 'غير مدفوع';
      default:
        return paymentStatus;
    }
  }

  /// هل يستطيع الطالب رفع أو إعادة رفع سند الدفع؟
  /// في الـ Backend:
  /// 1. أول رفع: status == 'pendingPayment' && expiresAt > now
  /// 2. إعادة الرفع بعد الرفض: status == 'rejected' && receiptResubmissionDeadline > now
  bool get canUploadReceipt {
    final now = DateTime.now();
    final norm = status.replaceAll('_', '').toLowerCase();

    if (norm == 'pendingpayment') {
      return expiresAt == null || expiresAt!.isAfter(now);
    }
    if (norm == 'rejected') {
      return receiptResubmissionDeadline == null ||
          receiptResubmissionDeadline!.isAfter(now);
    }
    return false;
  }

  /// هل انتهت مهلة السداد؟
  bool get isExpired {
    final norm = status.replaceAll('_', '').toLowerCase();
    if (norm == 'expired') return true;
    final now = DateTime.now();
    if (norm == 'pendingpayment' && expiresAt != null && expiresAt!.isBefore(now)) {
      return true;
    }
    if (norm == 'rejected' &&
        receiptResubmissionDeadline != null &&
        receiptResubmissionDeadline!.isBefore(now)) {
      return true;
    }
    return false;
  }

  factory StudentReservationModel.fromJson(Map<String, dynamic> json) {
    // استخراج بيانات الدورة بعد الـ populate
    String cId = '';
    String cTitle = 'دورة تدريبية';
    String? cImage;
    double cPrice = 0;
    double cDeposit = 0;
    String? cLoc;
    DateTime? cStart;
    DateTime? cEnd;

    final rawCourse = json['courseId'];
    if (rawCourse is Map<String, dynamic>) {
      cId = (rawCourse['_id'] ?? rawCourse['id'])?.toString() ?? '';
      cTitle = rawCourse['title']?.toString() ?? 'دورة تدريبية';
      cImage = rawCourse['image']?.toString();
      cPrice = _toDouble(rawCourse['price']);
      cDeposit = _toDouble(rawCourse['depositAmount']);
      cLoc = rawCourse['location']?.toString();
      cStart = _parseDate(rawCourse['startDate']);
      cEnd = _parseDate(rawCourse['endDate']);
    } else if (rawCourse != null) {
      cId = rawCourse.toString();
    }

    // استخراج بيانات المعهد بعد الـ populate
    String instId = '';
    String instName = 'المعهد التدريبي';
    String? instLogo;
    String? instAddress;

    final rawInstitute = json['instituteId'];
    if (rawInstitute is Map<String, dynamic>) {
      instId = (rawInstitute['_id'] ?? rawInstitute['id'])?.toString() ?? '';
      instName = rawInstitute['name']?.toString() ?? 'المعهد';
      instLogo = rawInstitute['logo']?.toString();
      instAddress = rawInstitute['address']?.toString();
    } else if (rawInstitute != null) {
      instId = rawInstitute.toString();
    }

    return StudentReservationModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      courseId: cId,
      courseTitle: cTitle,
      courseImage: cImage,
      coursePrice: cPrice,
      courseDeposit: cDeposit,
      courseLocation: cLoc,
      courseStartDate: cStart,
      courseEndDate: cEnd,
      instituteId: instId,
      instituteName: instName,
      instituteLogo: instLogo,
      instituteAddress: instAddress,
      studentName: json['studentName']?.toString() ?? '',
      studentPhone: json['studentPhone']?.toString() ?? '',
      bookingType: json['bookingType']?.toString() ?? 'online',
      paymentOption: json['paymentOption']?.toString() ?? 'full',
      totalAmount: _toDouble(json['totalAmount']),
      amountToPay: _toDouble(json['amountToPay']),
      amountPaid: _toDouble(json['amountPaid']),
      paymentStatus: json['paymentStatus']?.toString() ?? 'unpaid',
      status: json['status']?.toString() ?? 'pendingPayment',
      receiptPublicId: json['receiptPublicId']?.toString(),
      receiptUrl: json['receiptUrl']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      receiptResubmissionDeadline: _parseDate(json['receiptResubmissionDeadline']),
      expiresAt: _parseDate(json['expiresAt']),
      attendanceStatus: json['attendanceStatus']?.toString() ?? 'notMarked',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
