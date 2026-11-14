import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class CourseListInput extends StatefulWidget {
  const CourseListInput({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<List<String>> onChanged;

  @override
  State<CourseListInput> createState() => _CourseListInputState();
}

class _CourseListInputState extends State<CourseListInput> {
  final List<TextEditingController> _controllers = [TextEditingController()];

  void _emitChanged() {
    widget.onChanged(
      _controllers
          .map((controller) => controller.text.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }

  void _addItem() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeItem(int index) {
    final controller = _controllers.removeAt(index);
    controller.dispose();
    setState(() {});
    _emitChanged();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(widget.label, style: AppTypography.titleSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ..._controllers.indexed.map((entry) {
          final index = entry.$1;
          final controller = entry.$2;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textDirection: TextDirection.rtl,
                    onChanged: (_) => _emitChanged(),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'حذف العنصر',
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('إضافة عنصر'),
          ),
        ),
      ],
    );
  }
}
