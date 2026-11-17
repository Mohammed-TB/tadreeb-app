import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../models/student_reservation_model.dart';

class ReservationStatusSection extends StatelessWidget {
  const ReservationStatusSection({super.key, required this.reservation});

  final StudentReservationModel reservation;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(reservation.normalizedStatus);
    final reservationNumber = reservation.id.length > 8
        ? reservation.id.substring(reservation.id.length - 8)
        : reservation.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  reservation.courseTitle,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: style.foreground.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, size: 14, color: style.foreground),
                    const SizedBox(width: 4),
                    Text(
                      reservation.statusLabel,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: style.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.apartment_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reservation.instituteName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'رقم الحجز: #$reservationNumber',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.divider),
          _ReservationOrderTimeline(reservation: reservation),
        ],
      ),
    );
  }

  _ReservationStatusStyle _statusStyle(String status) {
    switch (status) {
      case 'confirmed':
        return const _ReservationStatusStyle(
          AppColors.success,
          AppColors.successLight,
          Icons.check_circle_rounded,
        );
      case 'paymentsubmitted':
        return const _ReservationStatusStyle(
          AppColors.primary,
          AppColors.primaryLight,
          Icons.hourglass_top_rounded,
        );
      case 'rejected':
        return const _ReservationStatusStyle(
          AppColors.error,
          AppColors.errorLight,
          Icons.cancel_rounded,
        );
      case 'pendingpayment':
        return const _ReservationStatusStyle(
          AppColors.accentDark,
          AppColors.accentLight,
          Icons.payment_rounded,
        );
      default:
        return const _ReservationStatusStyle(
          AppColors.textSecondary,
          AppColors.field,
          Icons.history_rounded,
        );
    }
  }
}

class _ReservationStatusStyle {
  const _ReservationStatusStyle(this.foreground, this.background, this.icon);

  final Color foreground;
  final Color background;
  final IconData icon;
}

class _ReservationOrderTimeline extends StatelessWidget {
  const _ReservationOrderTimeline({required this.reservation});

  final StudentReservationModel reservation;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = {
      'paymentsubmitted',
      'confirmed',
      'rejected',
    }.contains(reservation.normalizedStatus);
    final isConfirmed = reservation.normalizedStatus == 'confirmed';
    final isRejected = reservation.normalizedStatus == 'rejected';

    return Row(
      children: [
        _TimelineStep(
          icon: Icons.receipt_long_rounded,
          title: 'إنشاء الحجز',
          isDone: true,
        ),
        _TimelineLine(isDone: isSubmitted),
        _TimelineStep(
          icon: isRejected
              ? Icons.warning_amber_rounded
              : Icons.upload_file_rounded,
          title: isRejected ? 'سند مرفوض' : 'رفع السند',
          isDone: isSubmitted && !isRejected,
          isActive: isSubmitted && !isConfirmed,
          isError: isRejected,
        ),
        _TimelineLine(isDone: isConfirmed),
        _TimelineStep(
          icon: isConfirmed
              ? Icons.verified_rounded
              : Icons.assignment_turned_in_outlined,
          title: 'اعتماد المعهد',
          isDone: isConfirmed,
          isActive: isConfirmed,
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.title,
    this.isDone = false,
    this.isActive = false,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final bool isDone;
  final bool isActive;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final foreground = isError
        ? AppColors.error
        : isDone
        ? AppColors.success
        : isActive
        ? AppColors.primary
        : AppColors.textHint;
    final background = isError
        ? AppColors.errorLight
        : isDone
        ? AppColors.successLight
        : isActive
        ? AppColors.primaryLight
        : AppColors.field;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(
              color: foreground.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 16, color: foreground),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

class _TimelineLine extends StatelessWidget {
  const _TimelineLine({required this.isDone});

  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isDone ? AppColors.success : AppColors.border,
      ),
    );
  }
}
