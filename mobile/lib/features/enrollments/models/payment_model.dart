import '../../courses/models/course_model.dart';

enum PaymentType {
  deposit,
  full,
}

enum PaymentStatus {
  pendingReview,
  approved,
  rejected,
}

class PaymentModel {
  final String id;
  final String enrollmentId;

  final PaymentType type;
  final double amount;

  // Uploaded transfer receipt.
  final String receiptUrl;

  final PaymentStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  final String? rejectionReason;

  const PaymentModel({
    required this.id,
    required this.enrollmentId,
    required this.type,
    required this.amount,
    required this.receiptUrl,
    this.status = PaymentStatus.pendingReview,
    required this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
  }) : assert(amount > 0);


    PaymentModel copyWith({
    PaymentStatus? status,
    DateTime? reviewedAt,
    String? rejectionReason,
    bool clearRejectionReason = false,
  }) {
    return PaymentModel(
      id: id,
      enrollmentId: enrollmentId,
      type: type,
      amount: amount,
      receiptUrl: receiptUrl,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: clearRejectionReason
          ? null
          : rejectionReason ?? this.rejectionReason,
    );
  }

}
class PaymentCalculator {
  // Calculate the amount the student must pay.
  static double calculateAmount({
    required CourseModel course,
    required PaymentType paymentType,
  }) {
    switch (paymentType) {
      case PaymentType.deposit:
        return course.depositAmount;

      case PaymentType.full:
        return course.price;
    }
  }

  // Calculate the remaining amount after payment.
  static double calculateRemaining({
    required CourseModel course,
    required double paidAmount,
  }) {
    return (course.price - paidAmount)
        .clamp(0.0, course.price);
  }



}
