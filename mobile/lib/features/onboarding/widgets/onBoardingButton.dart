
import 'package:flutter/material.dart';

import '../../../core/widgets/button.dart';

class OnBoardingButton extends StatelessWidget {
  const OnBoardingButton({
    super.key,
    required this.text,
    this.isPrimary = true,
    this.onTap,
  });

  final String text;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Button(
      text: text,
      onTap: onTap,
      variant: isPrimary
          ? AppButtonVariant.primary
          : AppButtonVariant.outline,
      height: 48,
      borderRadius: 12,
    );
  }
}
