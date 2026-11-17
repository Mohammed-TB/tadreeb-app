import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/button.dart';
import '../../courses/controllers/reservation_controller.dart';
import '../models/student_reservation_model.dart';

class ReservationBalancePaymentScreen extends StatefulWidget {
  const ReservationBalancePaymentScreen({super.key, required this.reservation});

  final StudentReservationModel reservation;

  @override
  State<ReservationBalancePaymentScreen> createState() =>
      _ReservationBalancePaymentScreenState();
}

class _ReservationBalancePaymentScreenState
    extends State<ReservationBalancePaymentScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadReceipt(ImageSource source) async {
    final controller = context.read<ReservationController>();
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      final extension = picked.name.split('.').last.toLowerCase();
      final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
      final success = await controller.uploadBalancePaymentReceipt(
        reservationId: widget.reservation.id,
        fileBytes: bytes,
        fileName: picked.name,
        contentType: contentType,
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال سند الدفعة المتبقية لمراجعة المعهد'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر إرسال السند: ${controller.errorMessage ?? 'حاول مرة أخرى'}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء اختيار السند: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار صورة من المعرض'),
              onTap: () {
                Navigator.pop(modalContext);
                _pickAndUploadReceipt(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () {
                Navigator.pop(modalContext);
                _pickAndUploadReceipt(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title:  Text('إكمال سداد الرسوم',style:TextStyle(
            color: AppColors.surface
          ),),
          centerTitle: true,
                    leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Consumer<ReservationController>(
          builder: (context, controller, _) {
            final isUploading = controller.isUploadingFor(
              widget.reservation.id,
            );
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reservation.courseTitle,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _AmountRow(
                        label: 'إجمالي رسوم الدورة',
                        amount: widget.reservation.totalAmount,
                      ),
                      _AmountRow(
                        label: 'المبلغ المدفوع',
                        amount: widget.reservation.amountPaid,
                      ),
                      const Divider(height: AppSpacing.lg),
                      _AmountRow(
                        label: 'المبلغ المطلوب الآن',
                        amount: widget.reservation.remainingAmount,
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:  Text(
                    'حوّل المبلغ المتبقي إلى حساب المعهد، ثم أرفق صورة واضحة لإشعار التحويل. سيبقى تسجيلك مؤكدًا أثناء مراجعة الدفعة.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
                if (widget.reservation.balancePaymentStatus == 'rejected' &&
                    widget.reservation.balancePaymentRejectionReason !=
                        null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'سبب رفض السند السابق: ${widget.reservation.balancePaymentRejectionReason}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Button(
                  text: 'اختيار سند التحويل',
                  icon: Icons.upload_file_rounded,
                  height: 50,
                  isLoading: isUploading,
                  onTap: isUploading ? null : _showImageSourceDialog,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.isHighlighted = false,
  });

  final String label;
  final double amount;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMedium.copyWith(
      color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${amount.toStringAsFixed(2)} ريال', style: style),
        ],
      ),
    );
  }
}
