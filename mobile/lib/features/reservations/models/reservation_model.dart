/// نموذج حجز المعهد المطابق 100% للـ Backend (Tadreeb-Backend).
class ReservationModel {
  final String id;
  final String studentName;
  final String studentPhone;
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
  final String status; // pendingPayment | paymentSubmitted | confirmed | rejected | expired | cancelled
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
    required this.status,
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
  /// الـ reject يتطلب: status == 'paymentSubmitted' و bookingType == 'online'
  bool get canApproveOrReject {
    final s = status.toLowerCase();
    return s == 'paymentsubmitted' || s == 'payment_submitted';
  }

  /// هل يوجد إيصال مرفوع للمعاينة؟
  bool get hasReceipt {
    return (receiptPublicId != null && receiptPublicId!.isNotEmpty) ||
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

    return ReservationModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      studentPhone: json['studentPhone']?.toString() ?? '',
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
      status: json['status']?.toString() ?? 'pendingPayment',
      receiptPublicId: json['receiptPublicId']?.toString(),
      receiptUrl: json['receiptUrl']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      receiptResubmissionDeadline: _parseDate(json['receiptResubmissionDeadline']),
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
      'status': status,
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
