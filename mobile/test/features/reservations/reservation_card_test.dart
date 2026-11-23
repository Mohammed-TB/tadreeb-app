import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_1/features/reservations/models/reservation_model.dart';
import 'package:project_1/features/reservations/widgets/reservation_card.dart';

void main() {
  test('recognizes receipt availability without exposing its private ID', () {
    final reservation = ReservationModel.fromJson({
      '_id': 'reservation-1',
      'studentName': 'أحمد محمد',
      'studentPhone': '0500000000',
      'courseId': 'course-1',
      'bookingType': 'online',
      'paymentOption': 'full',
      'totalAmount': 500,
      'amountToPay': 500,
      'amountPaid': 0,
      'paymentStatus': 'unpaid',
      'status': 'paymentSubmitted',
      'hasReceipt': true,
    });

    expect(reservation.hasReceipt, isTrue);
    expect(reservation.receiptPublicId, isNull);
  });

  test(
    'uses the receipt flag and computes eligibility for partial payment',
    () {
      final reservation = ReservationModel.fromJson({
        '_id': 'reservation-1',
        'studentName': 'أحمد محمد',
        'studentPhone': '0500000000',
        'courseId': 'course-1',
        'bookingType': 'online',
        'paymentOption': 'deposit',
        'totalAmount': 1000,
        'amountToPay': 250,
        'amountPaid': 250,
        'paymentStatus': 'partial',
        'balancePaymentStatus': 'rejected',
        'hasBalanceReceipt': false,
        'status': 'confirmed',
      });

      expect(reservation.hasBalanceReceipt, isFalse);
      expect(reservation.remainingAmount, 750);
      expect(reservation.canRecordInPersonBalancePayment, isTrue);
    },
  );

  test('does not infer a receipt for in-person balance collection', () {
    final reservation = ReservationModel.fromJson({
      '_id': 'reservation-1',
      'studentName': 'أحمد محمد',
      'studentPhone': '0500000000',
      'courseId': 'course-1',
      'bookingType': 'online',
      'paymentOption': 'deposit',
      'totalAmount': 1000,
      'amountToPay': 250,
      'amountPaid': 1000,
      'paymentStatus': 'paid',
      'balancePaymentStatus': 'approved',
      'balancePaymentMethod': 'inPerson',
      'status': 'confirmed',
    });

    expect(reservation.hasBalanceReceipt, isFalse);
  });

  test(
    'allows new installments after approval but blocks pending payments',
    () {
      final reservation = ReservationModel.fromJson({
        '_id': 'reservation-1',
        'studentName': 'أحمد محمد',
        'studentPhone': '0500000000',
        'courseId': 'course-1',
        'bookingType': 'online',
        'paymentOption': 'deposit',
        'totalAmount': 1000,
        'amountToPay': 250,
        'amountPaid': 250,
        'paymentStatus': 'partial',
        'balancePaymentStatus': 'pending',
        'status': 'confirmed',
      });
      final approvedReservation = ReservationModel.fromJson({
        '_id': 'reservation-2',
        'studentName': 'أحمد محمد',
        'studentPhone': '0500000000',
        'courseId': 'course-1',
        'bookingType': 'online',
        'paymentOption': 'deposit',
        'totalAmount': 1000,
        'amountToPay': 250,
        'amountPaid': 250,
        'paymentStatus': 'partial',
        'balancePaymentStatus': 'approved',
        'status': 'confirmed',
      });

      expect(reservation.canRecordInPersonBalancePayment, isFalse);
      expect(approvedReservation.canRecordInPersonBalancePayment, isTrue);
    },
  );

  testWidgets('shows a compact reservation card and opens its details', (
    tester,
  ) async {
    var opened = false;
    final reservation = ReservationModel(
      id: 'reservation-1',
      studentName: 'أحمد محمد',
      studentPhone: '0500000000',
      courseId: 'course-1',
      courseTitle: 'دورة البرمجة',
      bookingType: 'online',
      paymentOption: 'full',
      totalAmount: 500,
      amountToPay: 500,
      amountPaid: 0,
      paymentStatus: 'unpaid',
      status: 'paymentSubmitted',
      createdAt: DateTime(2026, 11, 17),
      updatedAt: DateTime(2026, 11, 17),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReservationCard(
            reservation: reservation,
            onTap: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text('أحمد محمد'), findsOneWidget);
    expect(find.text('بانتظار المراجعة'), findsOneWidget);
    expect(find.text('دورة البرمجة'), findsNothing);
    await tester.tap(find.byType(ReservationCard));
    expect(opened, isTrue);
  });

  testWidgets('highlights a pending balance payment on the institute card', (
    tester,
  ) async {
    final reservation = ReservationModel(
      id: 'reservation-1',
      studentName: 'أحمد محمد',
      studentPhone: '0500000000',
      courseId: 'course-1',
      bookingType: 'online',
      paymentOption: 'deposit',
      totalAmount: 1000,
      amountToPay: 250,
      amountPaid: 250,
      paymentStatus: 'partial',
      balancePaymentAmount: 750,
      balancePaymentStatus: 'pending',
      status: 'confirmed',
      createdAt: DateTime(2026, 11, 17),
      updatedAt: DateTime(2026, 11, 17),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReservationCard(reservation: reservation, onTap: () {}),
        ),
      ),
    );

    expect(find.text('دفعة متبقية بانتظار المراجعة'), findsOneWidget);
  });

  testWidgets('highlights remaining amount for in-person collection', (
    tester,
  ) async {
    final reservation = ReservationModel(
      id: 'reservation-1',
      studentName: 'أحمد محمد',
      studentPhone: '0500000000',
      courseId: 'course-1',
      bookingType: 'online',
      paymentOption: 'deposit',
      totalAmount: 1000,
      amountToPay: 250,
      amountPaid: 250,
      paymentStatus: 'partial',
      status: 'confirmed',
      createdAt: DateTime(2026, 11, 17),
      updatedAt: DateTime(2026, 11, 17),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReservationCard(reservation: reservation, onTap: () {}),
        ),
      ),
    );

    expect(
      find.text('متبقي 750.00 ر.س · اضغط لتسجيل الاستلام'),
      findsOneWidget,
    );
  });
}
