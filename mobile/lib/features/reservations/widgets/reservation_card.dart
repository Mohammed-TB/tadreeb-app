import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/button.dart';
import '../models/reservation_model.dart';

/// بطاقة عرض حجز تفاعلية ذات UI/UX عالي الجودة مع إبراز أزرار القبول والرفض بناءً على بيانات Backend
class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewReceipt;
  final bool isProcessing;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.onApprove,
    required this.onReject,
    required this.onViewReceipt,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    // التحقق من أهلية الحجز لاتخاذ إجراء (قبول / رفض) من الـ Backend
    final bool canAct = reservation.canApproveOrReject;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // إذا كان الحجز بانتظار المراجعة، يتم تمييز حدوده بلون accent خفيف
          color: canAct ? AppColors.accent.withValues(alpha: 0.35) : AppColors.border,
          width: canAct ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: canAct
                ? AppColors.accent.withValues(alpha: 0.05)
                : AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة: الطالب والهاتف وشارة الحالة
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: canAct
                                ? AppColors.accentLight
                                : AppColors.primaryLight,
                            child: Text(
                              reservation.studentName.isNotEmpty
                                  ? reservation.studentName.characters.first
                                  : 'ط',
                              style: AppTypography.titleMedium.copyWith(
                                color: canAct
                                    ? AppColors.accentDark
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reservation.studentName,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      reservation.studentPhone,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (reservation.bookingType == 'inPerson') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.field,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'حضوري',
                                          style: AppTypography.labelSmall.copyWith(
                                            fontSize: 9,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // شارة حالة الحجز
                    _StatusBadge(status: reservation.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // اسم الدورة التدريبية
                if (reservation.courseTitle != null &&
                    reservation.courseTitle!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.field,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reservation.courseTitle!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.sm),

                // تفاصيل المدفوعات من الـ Backend
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _DetailItem(
                        icon: Icons.payments_outlined,
                        label: 'نوع الدفع',
                        value: _paymentOptionLabel(reservation.paymentOption),
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: AppColors.divider,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      _DetailItem(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'المطلوب / المدفوع',
                        value:
                            '${reservation.amountPaid} / ${reservation.amountToPay} ر.س',
                        valueColor: reservation.amountPaid > 0
                            ? AppColors.success
                            : AppColors.textPrimary,
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: AppColors.divider,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      _DetailItem(
                        icon: Icons.receipt_outlined,
                        label: 'الإجمالي الكلي',
                        value: '${reservation.totalAmount} ر.س',
                      ),
                    ],
                  ),
                ),

                // سبب الرفض إن وجد
                if (reservation.rejectionReason != null &&
                    reservation.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'سبب الرفض: ${reservation.rejectionReason}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // زر عرض السند / الإيصال إن توفر
                if (reservation.hasReceipt) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Material(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onViewReceipt,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              size: 16,
                              color: AppColors.accentDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'معاينة صورة السند / الإيصال المرفوع',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: AppColors.accentDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // شريط أزرار القبول والرفض - تظهر بكل وضوح عندما تكون حالة الحجز paymentSubmitted
          if (canAct) ...[
            const Divider(height: 1, color: AppColors.divider),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentLight.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // زر قبول وموافقة على الحجز (Button بنمط Accent)
                  Expanded(
                    flex: 3,
                    child: Button(
                      text: 'قبول وتأكيد الحجز',
                      variant: AppButtonVariant.accent,
                      icon: Icons.check_circle_outline_rounded,
                      height: 42,
                      isLoading: isProcessing,
                      onTap: onApprove,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // زر رفض الحجز (Button بنمط Outline)
                  Expanded(
                    flex: 2,
                    child: Button(
                      text: 'رفض',
                      variant: AppButtonVariant.outline,
                      icon: Icons.close_rounded,
                      height: 42,
                      isDisabled: isProcessing,
                      onTap: onReject,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _paymentOptionLabel(String option) {
    switch (option.toLowerCase()) {
      case 'full':
        return 'كامل';
      case 'deposit':
        return 'عربون';
      default:
        return option;
    }
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final norm = status.replaceAll('_', '').toLowerCase();
    final (label, color, bg) = switch (norm) {
      'confirmed' => ('مؤكد', AppColors.success, AppColors.successLight),
      'rejected' => ('مرفوض', AppColors.error, AppColors.errorLight),
      'paymentsubmitted' => ('بانتظار المراجعة', AppColors.accentDark, AppColors.accentLight),
      'pendingpayment' => ('بانتظار الدفع', AppColors.warning, AppColors.warningLight),
      'cancelled' => ('ملغي', AppColors.textHint, AppColors.field),
      'expired' => ('منتهي', AppColors.textHint, AppColors.field),
      _ => (status, AppColors.primary, AppColors.primaryLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
