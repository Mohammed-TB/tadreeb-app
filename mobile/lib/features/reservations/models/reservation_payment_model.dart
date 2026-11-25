class ReservationPaymentModel {
  const ReservationPaymentModel({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.hasReceipt,
    required this.createdAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final double amount;
  final String method;
  final String status;
  final bool hasReceipt;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  factory ReservationPaymentModel.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'])?.toString();
    final method = json['method']?.toString();
    final status = json['status']?.toString();
    final amount = json['amount'];
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (id == null ||
        method == null ||
        status == null ||
        amount is! num ||
        createdAt == null) {
      throw const FormatException('بيانات إحدى الدفعات غير صالحة');
    }
    return ReservationPaymentModel(
      id: id,
      amount: amount.toDouble(),
      method: method,
      status: status,
      hasReceipt: json['hasReceipt'] == true,
      createdAt: createdAt,
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}
