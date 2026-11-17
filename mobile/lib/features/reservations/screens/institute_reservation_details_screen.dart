import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/app_date_time_formatter.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../controllers/institute_reservation_controller.dart';
import '../models/reservation_model.dart';

class InstituteReservationDetailsScreen extends StatefulWidget {
  const InstituteReservationDetailsScreen({
    super.key,
    required this.reservation,
    required this.onApprove,
    required this.onReject,
  });

  final ReservationModel reservation;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  State<InstituteReservationDetailsScreen> createState() =>
      _InstituteReservationDetailsScreenState();
}

class _InstituteReservationDetailsScreenState
    extends State<InstituteReservationDetailsScreen> {
  String? _receiptUrl;
  bool _isLoadingReceipt = false;
  String? _receiptError;
  String? _balanceReceiptUrl;
  bool _isLoadingBalanceReceipt = false;

  @override
  void initState() {
    super.initState();
    _receiptUrl = widget.reservation.receiptUrl;
    if (widget.reservation.hasReceipt) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadReceipt());
    }
    if (widget.reservation.hasBalanceReceipt) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadBalanceReceipt(),
      );
    }
  }

  Future<void> _loadReceipt() async {
    if (!mounted) return;
    setState(() {
      _isLoadingReceipt = true;
      _receiptError = null;
    });

    final controller = context.read<InstituteReservationController>();
    final url = await controller.getReceiptUrl(widget.reservation.id);
    if (!mounted) return;
    setState(() {
      _receiptUrl = url ?? _receiptUrl;
      _isLoadingReceipt = false;
      if (_receiptUrl == null || _receiptUrl!.isEmpty) {
        _receiptError = controller.errorMessage ?? 'تعذر تحميل صورة السند';
      }
    });
  }

  Future<void> _loadBalanceReceipt() async {
    if (!mounted) return;
    setState(() => _isLoadingBalanceReceipt = true);
    final controller = context.read<InstituteReservationController>();
    final url = await controller.getBalancePaymentReceiptUrl(
      widget.reservation.id,
    );
    if (!mounted) return;
    setState(() {
      _balanceReceiptUrl = url;
      _isLoadingBalanceReceipt = false;
    });
  }

  ReservationModel _currentReservation(List<ReservationModel> reservations) {
    return reservations.firstWhere(
      (item) => item.id == widget.reservation.id,
      orElse: () => widget.reservation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: const AppDrawer(),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              tooltip: 'القائمة الرئيسية',
              color: Colors.white,
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text(
            'تفاصيل الحجز',
            style: TextStyle(color: AppColors.surface),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Consumer<InstituteReservationController>(
          builder: (context, controller, _) {
            final reservation = _currentReservation(controller.reservations);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _SectionCard(
                  title: 'بيانات الطالب',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _InfoRow(label: 'الاسم', value: reservation.studentName),
                    _InfoRow(
                      label: 'رقم الهاتف',
                      value: reservation.studentPhone,
                    ),
                    if (reservation.studentEmail?.isNotEmpty == true)
                      _InfoRow(
                        label: 'البريد الإلكتروني',
                        value: reservation.studentEmail!,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _SectionCard(
                  title: 'بيانات الحجز',
                  icon: Icons.event_note_outlined,
                  children: [
                    _InfoRow(
                      label: 'الدورة',
                      value: reservation.courseTitle ?? 'دورة تدريبية',
                    ),
                    if (reservation.coursePrice != null)
                      _InfoRow(
                        label: 'سعر الدورة',
                        value: _formatAmount(reservation.coursePrice!),
                      ),
                    if (reservation.courseDeposit != null)
                      _InfoRow(
                        label: 'عربون الدورة',
                        value: _formatAmount(reservation.courseDeposit!),
                      ),
                    _InfoRow(
                      label: 'نوع التسجيل',
                      value: _bookingTypeLabel(reservation.bookingType),
                    ),
                    _InfoRow(
                      label: 'حالة الحجز',
                      value: _statusLabel(reservation.status),
                    ),
                    _InfoRow(
                      label: 'تاريخ الحجز',
                      value: AppDateTimeFormatter.formatDateTime(
                        reservation.createdAt,
                        dayFirst: true,
                        use24HourClock: true,
                        separator: ' - ',
                      ),
                    ),
                    _InfoRow(
                      label: 'آخر تحديث',
                      value: AppDateTimeFormatter.formatDateTime(
                        reservation.updatedAt,
                        dayFirst: true,
                        use24HourClock: true,
                        separator: ' - ',
                      ),
                    ),
                    if (reservation.expiresAt != null)
                      _InfoRow(
                        label: 'انتهاء مهلة السداد',
                        value: AppDateTimeFormatter.formatDateTime(
                          reservation.expiresAt!,
                          dayFirst: true,
                          use24HourClock: true,
                          separator: ' - ',
                        ),
                      ),
                    if (reservation.receiptResubmissionDeadline != null)
                      _InfoRow(
                        label: 'آخر موعد لإعادة رفع السند',
                        value: AppDateTimeFormatter.formatDateTime(
                          reservation.receiptResubmissionDeadline!,
                          dayFirst: true,
                          use24HourClock: true,
                          separator: ' - ',
                        ),
                      ),
                    _InfoRow(
                      label: 'حالة الحضور',
                      value: _attendanceLabel(reservation.attendanceStatus),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _SectionCard(
                  title: 'تفاصيل الدفع',
                  icon: Icons.payments_outlined,
                  children: [
                    _InfoRow(
                      label: 'طريقة الدفع',
                      value: _paymentOptionLabel(reservation.paymentOption),
                    ),
                    _InfoRow(
                      label: 'حالة الدفع',
                      value: _paymentStatusLabel(reservation.paymentStatus),
                    ),
                    _InfoRow(
                      label: 'إجمالي الحجز',
                      value: _formatAmount(reservation.totalAmount),
                    ),
                    _InfoRow(
                      label: 'المبلغ المطلوب',
                      value: _formatAmount(reservation.amountToPay),
                    ),
                    _InfoRow(
                      label: 'المبلغ المدفوع',
                      value: _formatAmount(reservation.amountPaid),
                    ),
                  ],
                ),
                if (reservation.rejectionReason?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _SectionCard(
                    title: 'سبب الرفض',
                    icon: Icons.info_outline_rounded,
                    children: [
                      Text(
                        reservation.rejectionReason!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _buildReceiptSection(reservation),
                if (reservation.hasBalanceReceipt) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildBalancePaymentSection(reservation, controller),
                ],
                if (reservation.canApproveOrReject) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      if (reservation.bookingType != 'inPerson')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: controller.isProcessing(reservation.id)
                                ? null
                                : widget.onReject,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('رفض الحجز'),
                          ),
                        ),
                      if (reservation.bookingType != 'inPerson')
                        const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: controller.isProcessing(reservation.id)
                              ? null
                              : widget.onApprove,
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('قبول وتأكيد'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReceiptSection(ReservationModel reservation) {
    return _SectionCard(
      title: 'سند الدفع',
      icon: Icons.receipt_long_outlined,
      children: [
        if (!reservation.hasReceipt)
          Text('لا يوجد سند مرفوع لهذا الحجز.', style: AppTypography.bodyMedium)
        else if (_isLoadingReceipt)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_receiptUrl != null && _receiptUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              child: Image.network(
                _receiptUrl!,
                width: double.infinity,
                height: 320,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 120,
                  child: Center(child: Text('تعذر عرض صورة السند')),
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              Text(
                _receiptError ?? 'تعذر تحميل صورة السند',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
              TextButton.icon(
                onPressed: _loadReceipt,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBalancePaymentSection(
    ReservationModel reservation,
    InstituteReservationController controller,
  ) {
    final isPending = reservation.balancePaymentStatus == 'pending';
    final isProcessing = controller.isProcessing(reservation.id);
    return _SectionCard(
      title: 'سند إكمال الرسوم',
      icon: Icons.receipt_long_outlined,
      children: [
        _InfoRow(
          label: 'المبلغ المرفق',
          value: _formatAmount(reservation.balancePaymentAmount),
        ),
        _InfoRow(
          label: 'حالة الدفعة',
          value: switch (reservation.balancePaymentStatus) {
            'pending' => 'بانتظار المراجعة',
            'approved' => 'معتمدة',
            'rejected' => 'مرفوضة',
            _ => 'لا توجد دفعة',
          },
        ),
        if (reservation.balancePaymentRejectionReason?.isNotEmpty == true)
          _InfoRow(
            label: 'سبب الرفض',
            value: reservation.balancePaymentRejectionReason!,
          ),
        if (_isLoadingBalanceReceipt)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_balanceReceiptUrl != null && _balanceReceiptUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              child: Image.network(
                _balanceReceiptUrl!,
                width: double.infinity,
                height: 320,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 120,
                  child: Center(child: Text('تعذر عرض صورة السند')),
                ),
              ),
            ),
          )
        else
          TextButton.icon(
            onPressed: _loadBalanceReceipt,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة تحميل سند الدفعة'),
          ),
        if (isPending) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _rejectBalancePayment(controller, reservation),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('رفض السند'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _approveBalancePayment(controller, reservation),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('اعتماد الدفعة'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _approveBalancePayment(
    InstituteReservationController controller,
    ReservationModel reservation,
  ) async {
    final success = await controller.approveBalancePayment(reservation.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'تم اعتماد الدفعة وتحديث رصيد الطالب'
              : 'تعذر اعتماد الدفعة: ${controller.errorMessage ?? 'حاول مرة أخرى'}',
        ),
      ),
    );
  }

  Future<void> _rejectBalancePayment(
    InstituteReservationController controller,
    ReservationModel reservation,
  ) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض سند الدفعة'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'سبب الرفض',
            hintText: 'اكتب سببًا ليتمكن الطالب من إعادة الإرسال',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;

    final success = await controller.rejectBalancePayment(
      reservation.id,
      reason: reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'تم رفض السند وإشعار الطالب'
              : 'تعذر رفض السند: ${controller.errorMessage ?? 'حاول مرة أخرى'}',
        ),
      ),
    );
  }

  String _bookingTypeLabel(String value) =>
      value == 'inPerson' ? 'حضوري' : 'إلكتروني';

  String _statusLabel(String value) {
    final status = value.replaceAll('_', '').toLowerCase();
    return switch (status) {
      'pendingpayment' => 'بانتظار السداد',
      'paymentsubmitted' => 'بانتظار المراجعة',
      'confirmed' => 'مؤكد ومقبول',
      'rejected' => 'مرفوض',
      'expired' => 'منتهي',
      'cancelled' => 'ملغي',
      _ => value,
    };
  }

  String _paymentOptionLabel(String value) => value == 'deposit'
      ? 'عربون'
      : value == 'full'
      ? 'كامل'
      : value;

  String _paymentStatusLabel(String value) {
    return switch (value.toLowerCase()) {
      'paid' => 'مدفوع بالكامل',
      'partial' => 'مدفوع جزئيًا',
      'unpaid' => 'غير مدفوع',
      _ => value,
    };
  }

  String _attendanceLabel(String value) {
    return switch (value.toLowerCase()) {
      'attended' => 'حضر',
      'absent' => 'غائب',
      _ => 'لم يُحدد',
    };
  }

  String _formatAmount(double value) => '${value.toStringAsFixed(2)} ر.س';
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
