import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:project_1/features/institutes/models/institute_dashboard_model.dart';
import 'package:project_1/features/institutes/widgets/institute_dashboard_analytics.dart';

void main() {
  testWidgets(
    'monthly registration metric counts confirmed reservations only',
    (tester) async {
      const confirmedThisMonth = 42;
      const reservationsThisMonth = 91;
      final data = InstituteDashboardData(
        instituteName: 'معهد الاختبار',
        summary: const InstituteDashboardSummary(
          totalCourses: 0,
          publishedCourses: 0,
          totalReservations: 100,
          reservationsThisMonth: reservationsThisMonth,
          confirmedThisMonth: confirmedThisMonth,
          pendingPaymentThisMonth: 10,
          paymentSubmittedThisMonth: 11,
          rejectedThisMonth: 12,
          expiredThisMonth: 13,
          cancelledThisMonth: 14,
          receiptsToReview: 0,
          totalRevenue: 0,
          monthlyRevenue: [],
        ),
        courseOccupancy: const [],
        recentReservations: const [],
        alerts: const InstituteDashboardAlerts(
          coursesStartingSoon: 0,
          fullCourses: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: InstituteDashboardAnalytics(data: data),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final numberFormat = NumberFormat.decimalPattern('ar');
      expect(find.text('التسجيلات المؤكدة هذا الشهر'), findsOneWidget);
      expect(
        find.text(numberFormat.format(confirmedThisMonth)),
        findsNWidgets(2),
      );
      expect(
        find.text(numberFormat.format(reservationsThisMonth)),
        findsNothing,
      );
      expect(find.textContaining('إجمالي التسجيلات'), findsNothing);
    },
  );
}
