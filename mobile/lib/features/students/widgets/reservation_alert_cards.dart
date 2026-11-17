import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/app_date_time_formatter.dart';
import '../../../core/widgets/button.dart';
import '../models/student_reservation_model.dart';

class ReservationRejectedAlert extends StatelessWidget {
  const ReservationRejectedAlert({
    super.key,
    required this.reservation,
    required this.isUploading,
    required this.onUpload,
  });

  final StudentReservationModel reservation;
  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final canReupload = reservation.canUploadReceipt;
    final deadline = reservation.receiptResubmissionDeadline;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تم رفض سند التحويل من قبل المعهد',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'سبب الرفض: ${reservation.rejectionReason?.isNotEmpty == true ? reservation.rejectionReason : 'لم يحدد المعهد سبباً تفصيلياً'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (deadline != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      canReupload
                          ? 'مهلة إعادة الرفع تنتهي في: ${AppDateTimeFormatter.formatDateTime(deadline)}'
                          : 'انتهت مهلة إعادة رفع السند لهذا الحجز.',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: canReupload
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canReupload) ...[
            const SizedBox(height: 14),
            Button(
              text: 'إعادة رفع سند التحويل الآن',
              icon: Icons.cloud_upload_rounded,
              variant: AppButtonVariant.primary,
              height: 44,
              borderRadius: 12,
              isLoading: isUploading,
              onTap: onUpload,
            ),
          ],
        ],
      ),
    );
  }
}

class ReservationPendingPaymentAlert extends StatelessWidget {
  const ReservationPendingPaymentAlert({
    super.key,
    required this.reservation,
    required this.isUploading,
    required this.onUpload,
  });

  final StudentReservationModel reservation;
  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final canUpload = reservation.canUploadReceipt;
    final expiresAt = reservation.expiresAt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'يرجى سداد العربون وتأكيد الحجز',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'قم بتحويل مبلغ ${reservation.amountToPay} ريال لحساب المعهد وارفع صورة السند لحجز مقعدك.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 16,
                    color: AppColors.accentDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      canUpload
                          ? 'تنتهي مهلة السداد في: ${AppDateTimeFormatter.formatDateTime(expiresAt)}'
                          : 'انتهت صلاحية مهلة السداد.',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: canUpload
                            ? AppColors.accentDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canUpload) ...[
            const SizedBox(height: 14),
            Button(
              text: 'رفع سند التحويل البنكي',
              icon: Icons.upload_file_rounded,
              height: 44,
              borderRadius: 12,
              isLoading: isUploading,
              onTap: onUpload,
            ),
          ],
        ],
      ),
    );
  }
}
