import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../models/institute_dashboard_model.dart';

class InstituteDashboardActivity extends StatelessWidget {
  const InstituteDashboardActivity({super.key, required this.data});

  final InstituteDashboardData data;

  @override
  Widget build(BuildContext context) {
    final alertCount =
        data.summary.receiptsToReview +
        data.alerts.coursesStartingSoon +
        data.alerts.fullCourses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('آخر التسجيلات', 'الأحدث'),
        const SizedBox(height: AppSpacing.sm),
        _buildRecentReservations(),
        const SizedBox(height: AppSpacing.sectionGap),
        _sectionTitle(
          'تنبيهات تحتاج انتباهك',
          alertCount == 0 ? 'لا توجد' : '$alertCount تنبيه',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildAlerts(),
      ],
    );
  }

  Widget _buildRecentReservations() {
    final reservations = data.recentReservations;
    if (reservations.isEmpty) {
      return _EmptyActivityCard(
        icon: Icons.bookmark_border_rounded,
        message: 'لا توجد تسجيلات حتى الآن',
      );
    }

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < reservations.length; index++) ...[
            _ReservationTile(reservation: reservations[index]),
            if (index < reservations.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlerts() {
    final alerts = <Widget>[];
    final receiptsToReview = data.summary.receiptsToReview;
    if (receiptsToReview > 0) {
      alerts.add(
        _AlertTile(
          icon: Icons.receipt_long_outlined,
          title: '$receiptsToReview إيصالاً بانتظار المراجعة',
          subtitle: 'راجع الإيصالات لتأكيد التسجيلات',
          color: AppColors.warning,
          tint: AppColors.warningLight,
        ),
      );
    }
    if (data.alerts.coursesStartingSoon > 0) {
      alerts.add(
        _AlertTile(
          icon: Icons.event_outlined,
          title: '${data.alerts.coursesStartingSoon} دورة تبدأ قريباً',
          subtitle: 'تبدأ خلال الأيام السبعة القادمة',
          color: AppColors.primary,
          tint: AppColors.primaryLight,
        ),
      );
    }
    if (data.alerts.fullCourses > 0) {
      alerts.add(
        _AlertTile(
          icon: Icons.event_seat_outlined,
          title: '${data.alerts.fullCourses} دورة اكتملت مقاعدها',
          subtitle: 'وصلت الدورات المنشورة إلى سعتها',
          color: AppColors.success,
          tint: AppColors.successLight,
        ),
      );
    }

    if (alerts.isEmpty) {
      return const _EmptyActivityCard(
        icon: Icons.check_circle_outline_rounded,
        message: 'لا توجد تنبيهات تحتاج إلى إجراء حالياً',
      );
    }

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < alerts.length; index++) ...[
            alerts[index],
            if (index < alerts.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String trailing) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.titleMedium)),
        Text(
          trailing,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.reservation});

  final InstituteDashboardReservation reservation;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusTint) = switch (reservation.status) {
      InstituteDashboardReservationStatus.confirmed => (
        AppColors.success,
        AppColors.successLight,
      ),
      InstituteDashboardReservationStatus.paymentSubmitted => (
        AppColors.warning,
        AppColors.warningLight,
      ),
      InstituteDashboardReservationStatus.pendingPayment => (
        AppColors.primary,
        AppColors.primaryLight,
      ),
      InstituteDashboardReservationStatus.rejected => (
        AppColors.error,
        AppColors.errorLight,
      ),
      InstituteDashboardReservationStatus.expired => (
        AppColors.textSecondary,
        AppColors.field,
      ),
      InstituteDashboardReservationStatus.cancelled => (
        AppColors.textHint,
        AppColors.field,
      ),
    };
    final date = DateFormat(
      'yyyy/MM/dd',
    ).format(reservation.createdAt.toLocal());

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Text(
          reservation.studentName.substring(0, 1),
          style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
        ),
      ),
      title: Text(
        reservation.studentName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.titleSmall,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.courseTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(date, style: AppTypography.labelSmall),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: statusTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          reservation.status.label,
          style: AppTypography.labelSmall.copyWith(color: statusColor),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: tint,
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
