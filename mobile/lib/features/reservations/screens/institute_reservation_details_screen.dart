import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

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
                    if (reservation.studentEnglishName?.isNotEmpty == true)
                      _InfoRow(
                        label: 'الاسم بالإنجليزية',
                        value: reservation.studentEnglishName!,
                      ),
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
                    if (reservation.remainingAmount > 0)
                      _InfoRow(
                        label: 'المتبقي للسداد',
                        value: _formatAmount(reservation.remainingAmount),
                      ),
                    _InfoRow(
                      label: 'سياسة سداد المتبقي',
                      value: reservation.balancePaymentPolicy == 'installments'
                          ? 'أقساط، بحد أدنى ${_formatAmount(reservation.minimumInstallmentAmount)}'
                          : 'دفعة واحدة لكامل المتبقي',
                    ),
                    if (reservation.paymentStatus == 'paid' &&
                        reservation.balancePaymentStatus == 'approved')
                      _InfoRow(
                        label: 'طريقة سداد المتبقي',
                        value: reservation.balancePaymentMethod == 'inPerson'
                            ? 'استلام حضوري'
                            : 'تحويل بنكي',
                      ),
                    if (reservation.balancePaymentMethod == 'inPerson' &&
                        reservation.balancePaymentRecordedAt != null)
                      _InfoRow(
                        label: 'تاريخ الاستلام',
                        value: AppDateTimeFormatter.formatDateTime(
                          reservation.balancePaymentRecordedAt!,
                          dayFirst: true,
                          use24HourClock: true,
                          separator: ' - ',
                        ),
                      ),
                    if (reservation.balancePaymentStatus == 'pending')
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'يوجد سند تحويل للمتبقي بانتظار المراجعة؛ لا يمكن تسجيل استلام حضوري حتى تتم مراجعته.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    if (reservation.canRecordInPersonBalancePayment) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: controller.isProcessing(reservation.id)
                              ? null
                              : () => _recordInPersonBalancePayment(
                                  controller,
                                  reservation,
                                ),
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('تسجيل دفعة حضورية'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildPaymentHistory(reservation, controller),
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
                  SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentHistory(
    ReservationModel reservation,
    InstituteReservationController controller,
  ) {
    return _SectionCard(
      title: 'سجل جميع الدفعات',
      icon: Icons.receipt_long_outlined,
      children: reservation.payments.isEmpty
          ? [const Text('لا توجد دفعات مسجلة لهذا الحجز.')]
          : reservation.payments
                .map(
                  (payment) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'المبلغ',
                            value: _formatAmount(payment.amount),
                          ),
                          _InfoRow(
                            label: 'الطريقة',
                            value: payment.method == 'cash'
                                ? 'نقدًا'
                                : 'تحويل بنكي',
                          ),
                          _InfoRow(
                            label: 'الحالة',
                            value: _paymentRecordStatus(payment.status),
                          ),
                          _InfoRow(
                            label: 'تاريخ التسجيل',
                            value: AppDateTimeFormatter.formatDateTime(
                              payment.createdAt,
                              dayFirst: true,
                              use24HourClock: true,
                              separator: ' - ',
                            ),
                          ),
                          if (payment.rejectionReason?.isNotEmpty == true)
                            _InfoRow(
                              label: 'سبب الرفض',
                              value: payment.rejectionReason!,
                            ),
                          if (payment.hasReceipt)
                            TextButton.icon(
                              onPressed: () =>
                                  _showPaymentReceipt(payment.id, controller),
                              icon: const Icon(Icons.image_outlined),
                              label: const Text('عرض سند هذه الدفعة'),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
    );
  }

  Future<void> _showPaymentReceipt(
    String paymentId,
    InstituteReservationController controller,
  ) async {
    final url = await controller.getPaymentReceiptUrl(paymentId);
    if (!mounted) return;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل سند الدفعة: ${controller.errorMessage ?? 'حاول مرة أخرى'}',
          ),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            url,
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('تعذر عرض صورة السند'),
            ),
          ),
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

  Future<void> _recordInPersonBalancePayment(
    InstituteReservationController controller,
    ReservationModel reservation,
  ) async {
    final amountController = TextEditingController(
      text: reservation.remainingAmount.toStringAsFixed(2),
    );
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) {
        var method = 'cash';
        Uint8List? receiptBytes;
        String? receiptName;
        String? receiptContentType;
        String? validationMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('تسجيل دفعة من المعهد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'مبلغ الدفعة',
                      suffixText: AppCurrency.current.symbol,
                      helperText:
                          'المتبقي ${_formatAmount(reservation.remainingAmount)}'
                          '${reservation.balancePaymentPolicy == 'installments' ? '، الحد الأدنى ${_formatAmount(reservation.minimumInstallmentAmount)}' : ''}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('نقدًا')),
                      DropdownMenuItem(
                        value: 'bankTransfer',
                        child: Text('تحويل بنكي مع سند'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          method = value;
                          validationMessage = null;
                        });
                      }
                    },
                  ),
                  if (method == 'bankTransfer') ...[
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final image = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (image == null || !dialogContext.mounted) return;
                          final extension = image.name
                              .split('.')
                              .last
                              .toLowerCase();
                          const contentTypes = {
                            'jpg': 'image/jpeg',
                            'jpeg': 'image/jpeg',
                            'png': 'image/png',
                            'webp': 'image/webp',
                          };
                          final contentType = contentTypes[extension];
                          if (contentType == null) {
                            setDialogState(
                              () => validationMessage =
                                  'اختر صورة بصيغة JPG أو PNG أو WEBP',
                            );
                            return;
                          }
                          setDialogState(() {
                            receiptBytes = null;
                            validationMessage = 'جارٍ قراءة السند...';
                          });
                          final bytes = await image.readAsBytes();
                          if (bytes.length > 5 * 1024 * 1024) {
                            setDialogState(
                              () => validationMessage =
                                  'حجم الصورة يجب ألا يتجاوز 5 ميجابايت',
                            );
                            return;
                          }
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            receiptBytes = bytes;
                            receiptName = image.name;
                            receiptContentType = contentType;
                            validationMessage = null;
                          });
                        } on Exception catch (error) {
                          if (dialogContext.mounted) {
                            setDialogState(
                              () => validationMessage =
                                  'تعذر اختيار السند: $error',
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        receiptName ?? 'اختيار صورة السند',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (validationMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        validationMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim());
                  final amountError = _validateInstitutePaymentAmount(
                    amount,
                    reservation,
                  );
                  if (amountError != null) {
                    setDialogState(() => validationMessage = amountError);
                    return;
                  }
                  if (method == 'bankTransfer' && receiptBytes == null) {
                    setDialogState(
                      () => validationMessage = 'أرفق صورة سند التحويل',
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    'amount': amount!,
                    'method': method,
                    'receiptBytes': receiptBytes,
                    'receiptName': receiptName,
                    'receiptContentType': receiptContentType,
                  });
                },
                child: const Text('تسجيل الدفعة'),
              ),
            ],
          ),
        );
      },
    );
    amountController.dispose();
    if (result == null || !mounted) return;

    final method = result['method']! as String;
    final amount = result['amount']! as double;
    final success = method == 'cash'
        ? await controller.recordInPersonBalancePayment(
            reservation.id,
            amount: amount,
          )
        : await controller.recordInPersonTransferPayment(
            reservationId: reservation.id,
            amount: amount,
            fileBytes: result['receiptBytes']! as List<int>,
            fileName: result['receiptName']! as String,
            contentType: result['receiptContentType']! as String,
          );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'تم تسجيل الدفعة بنجاح'
              : 'تعذر تسجيل الدفعة: ${controller.errorMessage ?? 'حاول مرة أخرى'}',
        ),
      ),
    );
  }

  String? _validateInstitutePaymentAmount(
    double? amount,
    ReservationModel reservation,
  ) {
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > reservation.remainingAmount) {
      return 'أدخل مبلغًا صحيحًا لا يتجاوز المتبقي';
    }
    const epsilon = 0.005;
    if (reservation.balancePaymentPolicy == 'fullRemainder' &&
        (amount - reservation.remainingAmount).abs() >= epsilon) {
      return 'يجب سداد كامل المبلغ المتبقي';
    }
    if (reservation.balancePaymentPolicy == 'installments' &&
        amount + epsilon < reservation.minimumInstallmentAmount &&
        (amount - reservation.remainingAmount).abs() >= epsilon) {
      return 'المبلغ أقل من الحد الأدنى للقسط';
    }
    return null;
  }

  String _paymentRecordStatus(String status) => switch (status) {
    'pending' => 'قيد المراجعة',
    'approved' => 'معتمدة',
    'rejected' => 'مرفوضة',
    _ => status,
  };

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

  String _formatAmount(double value) =>
      CurrencyFormatter.format(value, decimalDigits: 2);
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
