
enum EnrollmentStatus {
  pendingReview,
  confirmed,
  rejected,
  expired,
  cancelled,
}

class EnrollmentModel {
  final String id;
  final String studentId;
  final String courseId;
  final String instituteId;

  // Snapshot of the course price when booking was created.
  final double coursePrice;
  final int depositPercentage;
  final double amountToPay;

  // Payment tracking.
  final double paidAmount;
  final String? currentPaymentId;

  // Booking lifecycle.
  final EnrollmentStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? confirmedAt;

  // Resubmission tracking.
  final int resubmissionCount;
  final String? lastRejectionReason;

  const EnrollmentModel({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.instituteId,
    required this.coursePrice,
    required this.depositPercentage,
    required this.amountToPay,
    this.paidAmount = 0,
    this.currentPaymentId,
    this.status = EnrollmentStatus.pendingReview,
    required this.createdAt,
    required this.expiresAt,
    this.confirmedAt,
    this.resubmissionCount = 0,
    this.lastRejectionReason,
  }) : assert(coursePrice >= 0),
       assert(depositPercentage >= 0 && depositPercentage <= 100),
       assert(amountToPay >= 0),
       assert(paidAmount >= 0),
       assert(resubmissionCount >= 0);

  double get remainingAmount =>
      (coursePrice - paidAmount).clamp(0.0, coursePrice);

  bool get isConfirmed => status == EnrollmentStatus.confirmed;

  bool get isExpired => status == EnrollmentStatus.expired;

  bool get canResubmit => status == EnrollmentStatus.rejected;


    EnrollmentModel copyWith({
    double? paidAmount,
    String? currentPaymentId,
    EnrollmentStatus? status,
    DateTime? expiresAt,
    DateTime? confirmedAt,
    int? resubmissionCount,
    String? lastRejectionReason,
    bool clearConfirmedAt = false,
    bool clearRejectionReason = false,
  }) {
    return EnrollmentModel(
      id: id,
      studentId: studentId,
      courseId: courseId,
      instituteId: instituteId,
      coursePrice: coursePrice,
      depositPercentage: depositPercentage,
      amountToPay: amountToPay,
      paidAmount: paidAmount ?? this.paidAmount,
      currentPaymentId: currentPaymentId ?? this.currentPaymentId,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      confirmedAt: clearConfirmedAt
          ? null
          : confirmedAt ?? this.confirmedAt,
      resubmissionCount: resubmissionCount ?? this.resubmissionCount,
      lastRejectionReason: clearRejectionReason
          ? null
          : lastRejectionReason ?? this.lastRejectionReason,
    );
  }

}
