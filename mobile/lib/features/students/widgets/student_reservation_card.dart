import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../models/student_reservation_model.dart';

/// بطاقة حجز الطالب المصممة بأعلى معايير الـ UI/UX
/// منظمة، واضحة، وخالية من العشوائية والتشتت
class StudentReservationCard extends StatelessWidget {
  final StudentReservationModel reservation;
  final VoidCallback onTap;
  final VoidCallback? onUploadReceipt;
  final bool isUploading;

  const StudentReservationCard({
    super.key,
    required this.reservation,
    required this.onTap,
    this.onUploadReceipt,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool canUpload = reservation.canUploadReceipt;
    final bool isRejected = reservation.normalizedStatus == 'rejected';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (reservation.normalizedStatus) {
      case 'confirmed':
        statusColor = AppColors.success;
        statusBg = AppColors.successLight;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'paymentsubmitted':
        statusColor = AppColors.primary;
        statusBg = AppColors.primaryLight;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusBg = AppColors.errorLight;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'pendingpayment':
        statusColor = AppColors.accentDark;
        statusBg = AppColors.accentLight;
        statusIcon = Icons.payment_rounded;
        break;
      case 'expired':
      case 'cancelled':
      default:
        statusColor = AppColors.textSecondary;
        statusBg = AppColors.field;
        statusIcon = Icons.history_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRejected
              ? AppColors.error.withValues(alpha: 0.4)
              : (canUpload
                  ? AppColors.accent.withValues(alpha: 0.35)
                  : AppColors.border),
          width: (isRejected || canUpload) ? 1.3 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ترويسة البطاقة: المعهد وشارة الحالة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reservation.instituteName,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            reservation.statusLabel,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. عنوان الدورة التدريبية
                Text(
                  reservation.courseTitle,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // 3. صف المعلومات المالية وتاريخ الحجز
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.field,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'المطلوب: ${reservation.amountToPay} ريال (${reservation.paymentOptionLabel})',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        intl.DateFormat('yyyy/MM/dd').format(reservation.createdAt),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. شريط تحذير الرفض (إذا كان السند مرفوضاً)
                if (isRejected) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'تم رفض السند: ${reservation.rejectionReason ?? 'اضغط لإعادة الرفع'}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // 5. زر التفاصيل والإجراء السريع
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'اضغط لعرض كافة التفاصيل',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: AppColors.textHint,
                      ),
                    ),
                    Row(
                      children: [
                        if (canUpload && onUploadReceipt != null) ...[
                          InkWell(
                            onTap: isUploading ? null : onUploadReceipt,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isRejected
                                    ? AppColors.error
                                    : AppColors.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: isUploading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isRejected
                                              ? Icons.replay_rounded
                                              : Icons.upload_file_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isRejected
                                              ? 'إعادة الرفع'
                                              : 'رفع السند',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
