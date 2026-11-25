import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_skeletons.dart';
import '../services/institute_payment_settings_service.dart';

class InstitutePaymentSettingsScreen extends StatefulWidget {
  const InstitutePaymentSettingsScreen({super.key});

  @override
  State<InstitutePaymentSettingsScreen> createState() =>
      _InstitutePaymentSettingsScreenState();
}

class _InstitutePaymentSettingsScreenState
    extends State<InstitutePaymentSettingsScreen> {
  final _minimumController = TextEditingController();
  final _hoursController = TextEditingController();
  String _policy = 'fullRemainder';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _minimumController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final settings = await context
          .read<InstitutePaymentSettingsService>()
          .getSettings();
      if (!mounted) return;
      setState(() {
        _policy = settings.balancePaymentPolicy;
        _minimumController.text = settings.minimumInstallmentAmount
            .toStringAsFixed(2);
        _hoursController.text = settings.receiptResubmissionHours.toString();
        _hasLoaded = true;
      });
    } on Exception catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final minimum = double.tryParse(_minimumController.text.trim());
    final hours = int.tryParse(_hoursController.text.trim());
    if (_policy == 'installments' &&
        (minimum == null || !minimum.isFinite || minimum <= 0)) {
      setState(() => _errorMessage = 'أدخل حدًا أدنى صحيحًا للقسط.');
      return;
    }
    if (hours == null || hours < 1 || hours > 72) {
      setState(
        () => _errorMessage =
            'مهلة إعادة رفع السند يجب أن تكون من ساعة إلى 72 ساعة.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await context.read<InstitutePaymentSettingsService>().updateSettings(
        receiptResubmissionHours: hours,
        policy: _policy,
        minimumInstallmentAmount: minimum ?? 1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات الحجز والدفع')),
      );
    } on Exception catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إعدادات الحجز والدفع')),
        body: _isLoading
            ? const AppSkeletonForm(fieldCount: 3)
            : !_hasLoaded
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage ?? 'تعذر تحميل إعدادات الحجز والدفع',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _load();
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'سياسة الحجز والدفع',
                              style: AppTypography.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'حدّد طريقة سداد الأرصدة والمهلة المتاحة لإعادة رفع سند الدفع.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        DropdownButtonFormField<String>(
                          initialValue: _policy,
                          decoration: const InputDecoration(
                            labelText: 'سياسة سداد الرصيد',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'fullRemainder',
                              child: Text('دفع كامل المبلغ المتبقي'),
                            ),
                            DropdownMenuItem(
                              value: 'installments',
                              child: Text('السداد على أقساط'),
                            ),
                          ],
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _policy = value);
                                  }
                                },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _policy == 'fullRemainder'
                              ? 'يلزم تسديد كامل الرصيد المتبقي في دفعة واحدة.'
                              : 'يمكن تسجيل عدة دفعات، ولا تقل الدفعة عن الحد الأدنى إلا إذا كانت هي آخر مبلغ متبقٍ.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_policy == 'installments') ...[
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _minimumController,
                            enabled: !_isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'الحد الأدنى لكل قسط',
                              suffixText: AppCurrency.current.symbol,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _hoursController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'مهلة إعادة رفع السند',
                            suffixText: 'ساعة',
                            helperText:
                                'المدة المسموح بها بعد رفض سند التحويل، من ساعة إلى 72 ساعة.',
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textOnPrimary,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            _isSaving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
      ),
    );
  }
}
