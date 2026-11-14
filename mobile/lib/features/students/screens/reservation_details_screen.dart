import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/button.dart';
import '../../courses/controllers/reservation_controller.dart';
import '../models/student_reservation_model.dart';

class ReservationDetailsScreen extends StatefulWidget {
  const ReservationDetailsScreen({
    super.key,
    required this.reservation,
  });

  final StudentReservationModel reservation;

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _receiptUrl;
  bool _isLoadingReceipt = false;
  late StudentReservationModel _reservation;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;

    // تشغيل جلب صورة السند بعد اكتمال بناء الإطار الأول لمنع أي تعليق في الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchReceiptUrl();
    });
  }

  Future<void> _fetchReceiptUrl() async {
    final r = _currentReservation;
    final hasReceiptUploaded = r.normalizedStatus == 'paymentsubmitted' ||
        r.normalizedStatus == 'confirmed' ||
        (r.normalizedStatus == 'rejected' && r.receiptPublicId != null);

    if (!hasReceiptUploaded) return;

    if (!mounted) return;
    setState(() {
      _isLoadingReceipt = true;
    });

    try {
      final url = await context
          .read<ReservationController>()
          .getReceiptUrl(r.id);
      if (mounted) {
        setState(() {
          _receiptUrl = url;
          _isLoadingReceipt = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingReceipt = false;
        });
      }
    }
  }

  StudentReservationModel get _currentReservation {
    final list = context.read<ReservationController>().myReservations;
    return list.firstWhere(
      (element) => element.id == _reservation.id,
      orElse: () => _reservation,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'م' : 'ص';
    return '$y/$m/$d $hour:$minute $period';
  }

  Future<void> _pickAndUploadReceipt(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<ReservationController>();
    final r = _currentReservation;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final fileName = picked.name;
      final ext = fileName.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final success = await controller.uploadReceipt(
        reservationId: r.id,
        fileBytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم رفع سند الدفع بنجاح وهو قيد مراجعة المعهد الآن',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchReceiptUrl();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('فشل رفع السند: ${controller.errorMessage}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء رفع الصورة: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اختيار صورة سند التحويل',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'المعرض (الاستوديو)',
                  style: AppTypography.bodyMedium,
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  _pickAndUploadReceipt(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.accentDark,
                  ),
                ),
                title: Text('الكاميرا', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(modalContext);
                  _pickAndUploadReceipt(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReceiptZoomDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'تعذر عرض السند',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReservationController>();
    final reservations = controller.myReservations;
    final r = reservations.firstWhere(
      (element) => element.id == _reservation.id,
      orElse: () => _reservation,
    );
    final isUploading = controller.isUploadingFor(r.id);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'تفاصيل الحجز',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'تحديث التفاصيل',
              onPressed: () {
                controller.fetchMyReservations();
                _fetchReceiptUrl();
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await controller.fetchMyReservations();
            await _fetchReceiptUrl();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. بطاقة ملخص الحالة العامة والمسار
                _buildStatusSummaryCard(r),
                const SizedBox(height: AppSpacing.md),

                // 2. تنبيه الرفض مع زر إعادة الرفع (إذا كانت الحالة مرفوضة)
                if (r.normalizedStatus == 'rejected') ...[
                  _buildRejectionAlertCard(r, isUploading),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 3. تنبيه بانتظار السداد مع زر الرفع (إذا لم يُرفع السند بعد)
                if (r.normalizedStatus == 'pendingpayment') ...[
                  _buildPendingPaymentAlertCard(r, isUploading),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 4. قسم سند الدفع
                _buildReceiptSection(r, isUploading),
                const SizedBox(height: AppSpacing.md),

                // 5. بطاقة تفاصيل الرسوم والسداد المالي
                _buildPaymentBreakdownCard(r),
                const SizedBox(height: AppSpacing.md),

                // 6. بطاقة معلومات الدورة والمعهد
                _buildCourseInfoCard(r),
                const SizedBox(height: AppSpacing.md),

                // 7. بطاقة بيانات الطالب المسجل
                _buildStudentInfoCard(r),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بطاقة ملخص الحالة العامة
  Widget _buildStatusSummaryCard(StudentReservationModel r) {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (r.normalizedStatus) {
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
      padding: const EdgeInsets.all(AppSpacing.md),
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
                  r.courseTitle,
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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      r.statusLabel,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
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
          Row(
            children: [
              const Icon(
                Icons.apartment_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                r.instituteName,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'رقم الحجز: #${r.id.length > 8 ? r.id.substring(r.id.length - 8) : r.id}',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.divider),

          // شريط الخطوات التوضيحي (Timeline)
          _buildOrderTimeline(r),
        ],
      ),
    );
  }

  // شريط مسار الحجز
  Widget _buildOrderTimeline(StudentReservationModel r) {
    final isSubmitted = r.normalizedStatus == 'paymentsubmitted' ||
        r.normalizedStatus == 'confirmed' ||
        r.normalizedStatus == 'rejected';
    final isConfirmed = r.normalizedStatus == 'confirmed';
    final isRejected = r.normalizedStatus == 'rejected';

    return Row(
      children: [
        _buildTimelineStep(
          icon: Icons.receipt_long_rounded,
          title: 'إنشاء الحجز',
          isDone: true,
          isActive: false,
        ),
        _buildTimelineLine(isDone: isSubmitted),
        _buildTimelineStep(
          icon: isRejected
              ? Icons.warning_amber_rounded
              : Icons.upload_file_rounded,
          title: isRejected ? 'سند مرفوض' : 'رفع السند',
          isDone: isSubmitted && !isRejected,
          isActive: isSubmitted && !isConfirmed,
          isError: isRejected,
        ),
        _buildTimelineLine(isDone: isConfirmed),
        _buildTimelineStep(
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

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required bool isDone,
    required bool isActive,
    bool isError = false,
  }) {
    Color bg;
    Color fg;

    if (isError) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
    } else if (isDone) {
      bg = AppColors.successLight;
      fg = AppColors.success;
    } else if (isActive) {
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
    } else {
      bg = AppColors.field;
      fg = AppColors.textHint;
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: fg.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 16, color: fg),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isDone ? AppColors.success : AppColors.border,
      ),
    );
  }

  // بطاقة تنبيه الرفض التفاعلية مع زر إعادة الرفع
  Widget _buildRejectionAlertCard(
    StudentReservationModel r,
    bool isUploading,
  ) {
    final canReupload = r.canUploadReceipt;
    final deadline = r.receiptResubmissionDeadline;

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
                      'سبب الرفض: ${r.rejectionReason?.isNotEmpty == true ? r.rejectionReason : 'لم يحدد المعهد سبباً تفصيلياً'}',
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
                          ? 'مهلة إعادة الرفع تنتهي في: ${_formatDateTime(deadline)}'
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
              onTap: _showImageSourceDialog,
            ),
          ],
        ],
      ),
    );
  }

  // بطاقة تنبيه السداد للحجز الجديد
  Widget _buildPendingPaymentAlertCard(
    StudentReservationModel r,
    bool isUploading,
  ) {
    final canUpload = r.canUploadReceipt;
    final expiresAt = r.expiresAt;

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
                      'قم بتحويل مبلغ ${r.amountToPay} ريال لحساب المعهد وارفع صورة السند لحجز مقعدك.',
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
                          ? 'تنتهي مهلة السداد في: ${_formatDateTime(expiresAt)}'
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
              onTap: _showImageSourceDialog,
            ),
          ],
        ],
      ),
    );
  }

  // قسم سند الدفع
  Widget _buildReceiptSection(
    StudentReservationModel r,
    bool isUploading,
  ) {
    final hasReceipt = _receiptUrl != null && _receiptUrl!.isNotEmpty;
    final canReupload = r.canUploadReceipt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'سند التحويل البنكي',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (canReupload && hasReceipt)
                TextButton.icon(
                  onPressed: isUploading ? null : _showImageSourceDialog,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(
                    'تعديل السند',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoadingReceipt)
            const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (hasReceipt)
            GestureDetector(
              onTap: () => _openReceiptZoomDialog(_receiptUrl!),
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
                      _receiptUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('تعذر تحميل الصورة'),
                      ),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
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
                      onTap: _showImageSourceDialog,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // بطاقة تفاصيل الرسوم والسداد المالي
  Widget _buildPaymentBreakdownCard(StudentReservationModel r) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'البيانات المالية والدفع',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildDataRow('إجمالي رسوم الدورة:', '${r.totalAmount} ريال'),
          _buildDataRow('نوع السداد المختار:', r.paymentOptionLabel),
          _buildDataRow(
            'المبلغ المطلوب سداده:',
            '${r.amountToPay} ريال',
            isHighlight: true,
            highlightColor: AppColors.primary,
          ),
          _buildDataRow('المبلغ المدفوع فعلياً:', '${r.amountPaid} ريال'),
          _buildDataRow(
            'حالة السداد:',
            r.paymentStatusLabel,
            isHighlight: true,
            highlightColor: r.paymentStatus == 'paid'
                ? AppColors.success
                : AppColors.accentDark,
          ),
        ],
      ),
    );
  }

  // بطاقة تفاصيل الدورة والمعهد
  Widget _buildCourseInfoCard(StudentReservationModel r) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'معلومات الدورة والتدريب',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildDataRow('اسم الدورة:', r.courseTitle),
          _buildDataRow('المعهد التدريبي:', r.instituteName),

          if (r.courseStartDate != null)
            _buildDataRow(
              'تاريخ البدء:',
              _formatDate(r.courseStartDate),
            ),

          if (r.courseEndDate != null)
            _buildDataRow(
              'تاريخ الانتهاء:',
              _formatDate(r.courseEndDate),
            ),

          if (r.courseLocation != null && r.courseLocation!.isNotEmpty)
            _buildDataRow('مكان الانعقاد:', r.courseLocation!),

          _buildDataRow(
            'نوع التسجيل:',
            r.bookingType == 'online' ? 'إلكتروني عبر المنصة' : 'حضوري',
          ),
        ],
      ),
    );
  }

  // بطاقة بيانات الطالب
  Widget _buildStudentInfoCard(StudentReservationModel r) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'بيانات المتدرب المسجل',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildDataRow('اسم الطالب:', r.studentName),
          _buildDataRow('رقم الهاتف:', r.studentPhone),
          _buildDataRow(
            'تاريخ إنشاء الحجز:',
            _formatDateTime(r.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight
                    ? (highlightColor ?? AppColors.textPrimary)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
