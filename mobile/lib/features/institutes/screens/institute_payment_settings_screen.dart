import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_spacing.dart';
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
    if (_policy == 'installments' &&
        (minimum == null || !minimum.isFinite || minimum <= 0)) {
      setState(() => _errorMessage = 'أدخل حدًا أدنى صحيحًا للقسط');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await context.read<InstitutePaymentSettingsService>().updateSettings(
        policy: _policy,
        minimumInstallmentAmount: minimum ?? 1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ سياسة الدفع')));
    } on Exception catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الحجز والدفع')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasLoaded
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage ?? 'تعذر تحميل إعدادات الدفع',
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
                DropdownButtonFormField<String>(
                  initialValue: _policy,
                  decoration: const InputDecoration(
                    labelText: 'طريقة سداد المتبقي',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'fullRemainder',
                      child: Text('دفع كامل المبلغ المتبقي دفعة واحدة'),
                    ),
                    DropdownMenuItem(
                      value: 'installments',
                      child: Text('السماح بالتقسيط'),
                    ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _policy = value);
                        },
                ),
                if (_policy == 'installments') ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _minimumController,
                    enabled: !_isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'الحد الأدنى لكل قسط',
                      suffixText: 'ريال',
                      helperText:
                          'يُسمح بدفع المتبقي النهائي إذا كان أقل من هذا الحد.',
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات'),
                ),
              ],
            ),
    );
  }
}
