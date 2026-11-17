import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/button.dart';
import '../models/student_reservation_model.dart';
import 'reservation_details_components.dart';

class ReservationReceiptSection extends StatelessWidget {
  const ReservationReceiptSection({
    super.key,
    required this.reservation,
    required this.receiptUrl,
    required this.isLoading,
    required this.isUploading,
    required this.onSelectReceipt,
    required this.onOpenReceipt,
  });

  final StudentReservationModel reservation;
  final String? receiptUrl;
  final bool isLoading;
  final bool isUploading;
  final VoidCallback onSelectReceipt;
  final VoidCallback onOpenReceipt;

  @override
  Widget build(BuildContext context) {
    final hasReceipt = receiptUrl?.isNotEmpty == true;
    final canReupload = reservation.canUploadReceipt;

    return ReservationSectionCard(
      title: 'سند التحويل البنكي',
      icon: Icons.receipt_rounded,
      children: [
        if (canReupload && hasReceipt)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: isUploading ? null : onSelectReceipt,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(
                'تعديل السند',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
            ),
          ),
        if (isLoading)
          const SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (hasReceipt)
          GestureDetector(
            onTap: onOpenReceipt,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                color: AppColors.field,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    receiptUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Text('تعذر تحميل الصورة')),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.zoom_in_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'اضغط للتكبير',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 40,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 8),
                Text(
                  'لم يتم رفع سند التحويل بعد',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'ارفع صورة إشعار التحويل البنكي لمراجعتها واعتماد مقعدك',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (canReupload) ...[
                  const SizedBox(height: 14),
                  Button(
                    text: 'اختيار صورة السند',
                    icon: Icons.add_photo_alternate_outlined,
                    height: 40,
                    borderRadius: 10,
                    width: 180,
                    isLoading: isUploading,
                    onTap: onSelectReceipt,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class ReservationPaymentSection extends StatelessWidget {
  const ReservationPaymentSection({
    super.key,
    required this.reservation,
    required this.onPayBalance,
  });

  final StudentReservationModel reservation;
  final VoidCallback onPayBalance;

  @override
  Widget build(BuildContext context) {
    return ReservationSectionCard(
      title: 'البيانات المالية والدفع',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        ReservationDataRow(
          label: 'إجمالي رسوم الدورة:',
          value: '${reservation.totalAmount} ريال',
        ),
        ReservationDataRow(
          label: 'نوع السداد المختار:',
          value: reservation.paymentOptionLabel,
        ),
        ReservationDataRow(
          label: 'المبلغ المطلوب سداده:',
          value: '${reservation.amountToPay} ريال',
          isHighlight: true,
          highlightColor: AppColors.primary,
        ),
        ReservationDataRow(
          label: 'المبلغ المدفوع فعلياً:',
          value: '${reservation.amountPaid} ريال',
        ),
        ReservationDataRow(
          label: 'المبلغ المتبقي:',
          value: '${reservation.remainingAmount} ريال',
          isHighlight: reservation.remainingAmount > 0,
          highlightColor: AppColors.accentDark,
        ),
        ReservationDataRow(
          label: 'حالة السداد:',
          value: reservation.paymentStatusLabel,
          isHighlight: true,
          highlightColor: reservation.paymentStatus == 'paid'
              ? AppColors.success
              : AppColors.accentDark,
        ),
        if (reservation.canPayBalance) ...[
          const SizedBox(height: 14),
          Button(
            text: reservation.balancePaymentStatus == 'rejected'
                ? 'إعادة إرسال سند الدفعة المتبقية'
                : 'إكمال سداد الرسوم',
            icon: Icons.payments_rounded,
            height: 48,
            onTap: onPayBalance,
          ),
        ],
      ],
    );
  }
}

class BalancePaymentNotice extends StatelessWidget {
  const BalancePaymentNotice({
    super.key,
    required this.message,
    required this.textColor,
    required this.backgroundColor,
  });

  final String message;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
