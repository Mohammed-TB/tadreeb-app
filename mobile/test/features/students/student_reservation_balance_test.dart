import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/reservations/models/reservation_model.dart';
import 'package:project_1/features/students/models/student_reservation_model.dart';

void main() {
  StudentReservationModel reservation({
    String status = 'confirmed',
    String paymentStatus = 'partial',
    String balancePaymentStatus = 'none',
    double amountPaid = 250,
  }) {
    return StudentReservationModel.fromJson({
      '_id': 'reservation-1',
      'courseId': {'_id': 'course-1', 'title': 'دورة اختبار'},
      'totalAmount': 1000,
      'amountToPay': 250,
      'amountPaid': amountPaid,
      'paymentStatus': paymentStatus,
      'balancePaymentStatus': balancePaymentStatus,
      'status': status,
    });
  }

  test('allows a confirmed partially-paid reservation to pay its balance', () {
    final result = reservation();

    expect(result.remainingAmount, 750);
    expect(result.canPayBalance, isTrue);
  });

  test(
    'does not allow balance payment while the submitted payment is pending',
    () {
      expect(
        reservation(balancePaymentStatus: 'pending').canPayBalance,
        isFalse,
      );
    },
  );

  test('requires a confirmed partial reservation with a positive balance', () {
    expect(reservation(status: 'paymentSubmitted').canPayBalance, isFalse);
    expect(reservation(paymentStatus: 'paid').canPayBalance, isFalse);
    expect(reservation(amountPaid: 1000).canPayBalance, isFalse);
  });

  test('allows resubmission after a rejected balance receipt', () {
    expect(reservation(balancePaymentStatus: 'rejected').canPayBalance, isTrue);
  });

  test('allows a new installment after an earlier installment is approved', () {
    expect(
      reservation(
        balancePaymentStatus: 'approved',
        amountPaid: 400,
      ).canPayBalance,
      isTrue,
    );
  });

  test('parses payment history including rejected attempts and receipts', () {
    final result = StudentReservationModel.fromJson({
      '_id': 'reservation-1',
      'courseId': {'_id': 'course-1', 'title': 'دورة اختبار'},
      'totalAmount': 1000,
      'amountToPay': 250,
      'amountPaid': 250,
      'paymentStatus': 'partial',
      'status': 'confirmed',
      'payments': [
        {
          '_id': 'payment-1',
          'amount': 100,
          'method': 'bankTransfer',
          'status': 'rejected',
          'hasReceipt': true,
          'createdAt': '2026-03-10T12:00:00.000Z',
          'rejectionReason': 'السند غير واضح',
        },
      ],
    });

    expect(result.payments, hasLength(1));
    expect(result.payments.single.status, 'rejected');
    expect(result.payments.single.hasReceipt, isTrue);
    expect(result.payments.single.rejectionReason, 'السند غير واضح');
  });

  test('keeps the balance receipt visible after institute review', () {
    final result = ReservationModel.fromJson({
      '_id': 'reservation-1',
      'studentName': 'طالب',
      'studentPhone': '0500000000',
      'courseId': 'course-1',
      'bookingType': 'online',
      'paymentOption': 'deposit',
      'totalAmount': 1000,
      'amountToPay': 250,
      'amountPaid': 1000,
      'paymentStatus': 'paid',
      'status': 'confirmed',
      'balancePaymentStatus': 'approved',
    });

    expect(result.hasBalanceReceipt, isTrue);
  });
}
