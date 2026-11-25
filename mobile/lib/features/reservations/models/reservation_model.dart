import 'reservation_payment_model.dart';

class ReservationModel {
  final String id;
  final String studentName;
  final String studentPhone;
  final String? studentEnglishName;
  final String? studentEmail;
  final String courseId;
  final String? courseTitle;
  final double? coursePrice;
  final double? courseDeposit;
  final String bookingType; // online | inPerson
  final String paymentOption; // full | deposit
  final double totalAmount;
  final double amountToPay;
  final double amountPaid;
  final String paymentStatus; // unpaid | partial | paid
  final double balancePaymentAmount;
  final String balancePaymentStatus; // none | pending | approved | rejected
  final String balancePaymentPolicy;
  final double minimumInstallmentAmount;
  final List<ReservationPaymentModel> payments;
  final String? balancePaymentMethod; // bankTransfer | inPerson
  final DateTime? balancePaymentRecordedAt;
  final bool hasBalanceReceipt;
  final String? balancePaymentRejectionReason;
  final String
  status; // pendingPayment | paymentSubmitted | confirmed | rejected | expired | cancelled
  final bool receiptAvailable;
  final String? receiptPublicId;
  final String? receiptUrl;
  final String? rejectionReason;
  final DateTime? receiptResubmissionDeadline;
  final String attendanceStatus; // notMarked | attended | absent
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReservationModel({
    required this.id,
    required this.studentName,
    required this.studentPhone,
    this.studentEnglishName,
    this.studentEmail,
    required this.courseId,
    this.courseTitle,
    this.coursePrice,
    this.courseDeposit,
    required this.bookingType,
    required this.paymentOption,
    required this.totalAmount,
    required this.amountToPay,
    required this.amountPaid,
    required this.paymentStatus,
    this.balancePaymentAmount = 0,
    this.balancePaymentStatus = 'none',
    this.balancePaymentPolicy = 'fullRemainder',
    this.minimumInstallmentAmount = 1,
    this.payments = const [],
    this.balancePaymentMethod,
    this.balancePaymentRecordedAt,
    this.hasBalanceReceipt = false,
    this.balancePaymentRejectionReason,
    required this.status,
    this.receiptAvailable = false,
    this.receiptPublicId,
    this.receiptUrl,
    this.rejectionReason,
    this.receiptResubmissionDeadline,
    this.attendanceStatus = 'notMarked',
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// هل الحجز مؤهل للقبول أو الرفض من قبل المعهد؟
  /// في الـ Backend:
  /// الـ approve يتطلب: status == 'paymentSubmitted'
  /// والرفض متاح للحجوزات الإلكترونية والحضورية المعلقة.
  bool get canApproveOrReject {
    final s = status.toLowerCase();
    return s == 'paymentsubmitted' || s == 'payment_submitted';
  }

  double get remainingAmount =>
      (totalAmount - amountPaid).clamp(0, double.infinity).toDouble();

  bool get canRecordInPersonBalancePayment =>
      status.toLowerCase() == 'confirmed' &&
      paymentStatus.toLowerCase() == 'partial' &&
      remainingAmount > 0 &&
      balancePaymentStatus.toLowerCase() != 'pending';

  /// هل يوجد إيصال مرفوع للمعاينة؟
  bool get hasReceipt {
    return receiptAvailable ||
        (receiptPublicId != null && receiptPublicId!.isNotEmpty) ||
        (receiptUrl != null && receiptUrl!.isNotEmpty);
  }

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    // معالجة courseId إما كـ ObjectId أو كـ Object معمولة له populate
    String courseIdStr = '';
    String? courseTitleStr;
    double? cPrice;
    double? cDeposit;

    final rawCourse = json['courseId'];
    if (rawCourse is Map<String, dynamic>) {
      courseIdStr = (rawCourse['_id'] ?? rawCourse['id'])?.toString() ?? '';
      courseTitleStr = rawCourse['title']?.toString();
      cPrice = _toDouble(rawCourse['price']);
      cDeposit = _toDouble(rawCourse['depositAmount']);
    } else if (rawCourse != null) {
      courseIdStr = rawCourse.toString();
      courseTitleStr = json['courseTitle']?.toString();
    }

    // معالجة studentId إذا معمولة له populate
    String? sEmail;
    final rawStudent = json['studentId'];
    if (rawStudent is Map<String, dynamic>) {
      sEmail = rawStudent['email']?.toString();
    }

    final balancePaymentMethod = json['balancePaymentMethod']?.toString();
    final balancePaymentStatus = json['balancePaymentStatus']
        ?.toString()
        .toLowerCase();
    final rawHasBalanceReceipt = json['hasBalanceReceipt'];
    final hasBalanceReceipt = rawHasBalanceReceipt is bool
        ? rawHasBalanceReceipt
        : balancePaymentMethod != 'inPerson' &&
              const {
                'pending',
                'approved',
                'rejected',
              }.contains(balancePaymentStatus);

    return ReservationModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      studentPhone: json['studentPhone']?.toString() ?? '',
      studentEnglishName: json['studentEnglishName']?.toString(),
      studentEmail: sEmail ?? json['studentEmail']?.toString(),
      courseId: courseIdStr,
      courseTitle: courseTitleStr,
      coursePrice: cPrice,
      courseDeposit: cDeposit,
      bookingType: json['bookingType']?.toString() ?? 'online',
      paymentOption: json['paymentOption']?.toString() ?? 'full',
      totalAmount: _toDouble(json['totalAmount']),
      amountToPay: _toDouble(json['amountToPay']),
      amountPaid: _toDouble(json['amountPaid']),
      paymentStatus: json['paymentStatus']?.toString() ?? 'unpaid',
      balancePaymentAmount: _toDouble(json['balancePaymentAmount']),
      balancePaymentStatus: json['balancePaymentStatus']?.toString() ?? 'none',
      balancePaymentPolicy:
          json['balancePaymentPolicy']?.toString() ?? 'fullRemainder',
      minimumInstallmentAmount: _toDouble(
        json['minimumInstallmentAmount'] ?? 1,
      ),
      payments: json['payments'] is List
          ? (json['payments'] as List)
                .whereType<Map<String, dynamic>>()
                .map(ReservationPaymentModel.fromJson)
                .toList()
          : const [],
      balancePaymentMethod: balancePaymentMethod,
      balancePaymentRecordedAt: _parseDate(json['balancePaymentRecordedAt']),
      hasBalanceReceipt: hasBalanceReceipt,
      balancePaymentRejectionReason: json['balancePaymentRejectionReason']
          ?.toString(),
      status: json['status']?.toString() ?? 'pendingPayment',
      receiptAvailable: json['hasReceipt'] == true,
      receiptPublicId: json['receiptPublicId']?.toString(),
      receiptUrl: json['receiptUrl']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      receiptResubmissionDeadline: _parseDate(
        json['receiptResubmissionDeadline'],
      ),
      attendanceStatus: json['attendanceStatus']?.toString() ?? 'notMarked',
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'studentPhone': studentPhone,
      'courseId': courseId,
      if (courseTitle != null) 'courseTitle': courseTitle,
      'bookingType': bookingType,
      'paymentOption': paymentOption,
      'totalAmount': totalAmount,
      'amountToPay': amountToPay,
      'amountPaid': amountPaid,
      'paymentStatus': paymentStatus,
      'balancePaymentAmount': balancePaymentAmount,
      'balancePaymentStatus': balancePaymentStatus,
      if (balancePaymentMethod != null)
        'balancePaymentMethod': balancePaymentMethod,
      if (balancePaymentRecordedAt != null)
        'balancePaymentRecordedAt': balancePaymentRecordedAt!.toIso8601String(),
      'hasBalanceReceipt': hasBalanceReceipt,
      if (balancePaymentRejectionReason != null)
        'balancePaymentRejectionReason': balancePaymentRejectionReason,
      'status': status,
      'hasReceipt': hasReceipt,
      if (receiptPublicId != null) 'receiptPublicId': receiptPublicId,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
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
