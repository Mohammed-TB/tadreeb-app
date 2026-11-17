import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../courses/controllers/reservation_controller.dart';
import '../models/student_reservation_model.dart';
import '../widgets/reservation_alert_cards.dart';
import '../widgets/reservation_information_sections.dart';
import '../widgets/reservation_payment_sections.dart';
import '../widgets/reservation_status_section.dart';

class ReservationDetailsScreen extends StatefulWidget {
  const ReservationDetailsScreen({super.key, required this.reservation});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchReceiptUrl();
    });
  }

  StudentReservationModel get _currentReservation {
    final reservations = context.read<ReservationController>().myReservations;
    return reservations.firstWhere(
      (reservation) => reservation.id == _reservation.id,
      orElse: () => _reservation,
    );
  }

  Future<void> _fetchReceiptUrl() async {
    final reservation = _currentReservation;
    final hasReceiptUploaded =
        reservation.normalizedStatus == 'paymentsubmitted' ||
        reservation.normalizedStatus == 'confirmed' ||
        (reservation.normalizedStatus == 'rejected' &&
            reservation.receiptPublicId != null);

    if (!hasReceiptUploaded || !mounted) return;
    setState(() => _isLoadingReceipt = true);

    try {
      final url = await context.read<ReservationController>().getReceiptUrl(
        reservation.id,
      );
      if (!mounted) return;
      setState(() {
        _receiptUrl = url;
        _isLoadingReceipt = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingReceipt = false);
    }
  }

  Future<void> _pickAndUploadReceipt(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<ReservationController>();
    final reservation = _currentReservation;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final extension = picked.name.split('.').last.toLowerCase();
      final success = await controller.uploadReceipt(
        reservationId: reservation.id,
        fileBytes: bytes,
        fileName: picked.name,
        contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
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
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء رفع الصورة: $error'),
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
                maxScale: 4,
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

  Future<void> _openBalancePayment(StudentReservationModel reservation) async {
    final submitted = await context.push<bool>(
      '/reservation-balance-payment',
      extra: reservation,
    );
    if (submitted == true && mounted) {
      await context.read<ReservationController>().fetchMyReservations(
        forceRefresh: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReservationController>();
    final reservation = controller.myReservations.firstWhere(
      (item) => item.id == _reservation.id,
      orElse: () => _reservation,
    );
    final isUploading = controller.isUploadingFor(reservation.id);

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
                ReservationStatusSection(reservation: reservation),
                const SizedBox(height: AppSpacing.md),
                if (reservation.normalizedStatus == 'rejected') ...[
                  ReservationRejectedAlert(
                    reservation: reservation,
                    isUploading: isUploading,
                    onUpload: _showImageSourceDialog,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (reservation.normalizedStatus == 'pendingpayment') ...[
                  ReservationPendingPaymentAlert(
                    reservation: reservation,
                    isUploading: isUploading,
                    onUpload: _showImageSourceDialog,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                ReservationReceiptSection(
                  reservation: reservation,
                  receiptUrl: _receiptUrl,
                  isLoading: _isLoadingReceipt,
                  isUploading: isUploading,
                  onSelectReceipt: _showImageSourceDialog,
                  onOpenReceipt: () {
                    if (_receiptUrl != null) {
                      _openReceiptZoomDialog(_receiptUrl!);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ReservationPaymentSection(
                  reservation: reservation,
                  onPayBalance: () => _openBalancePayment(reservation),
                ),
                if (reservation.balancePaymentStatus == 'pending') ...[
                  const SizedBox(height: AppSpacing.sm),
                  const BalancePaymentNotice(
                    message: 'سند الدفعة المتبقية قيد مراجعة المعهد.',
                    textColor: AppColors.accentDark,
                    backgroundColor: AppColors.accentLight,
                  ),
                ] else if (reservation.balancePaymentStatus == 'rejected') ...[
                  const SizedBox(height: AppSpacing.sm),
                  BalancePaymentNotice(
                    message:
                        'تم رفض سند الدفعة المتبقية${reservation.balancePaymentRejectionReason?.isNotEmpty == true ? ': ${reservation.balancePaymentRejectionReason}' : ''}',
                    textColor: AppColors.error,
                    backgroundColor: AppColors.errorLight,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                ReservationCourseInfoSection(reservation: reservation),
                const SizedBox(height: AppSpacing.md),
                ReservationStudentInfoSection(reservation: reservation),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
