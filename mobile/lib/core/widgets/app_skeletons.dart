import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class AppSkeletonizer extends StatelessWidget {
  const AppSkeletonizer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      ignoreContainers: true,
      effect: const ShimmerEffect(
        baseColor: AppColors.field,
        highlightColor: AppColors.surface,
        duration: Duration(milliseconds: 1200),
      ),
      child: child,
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 4,
    this.padding = EdgeInsets.zero,
    this.leadingSize = 64,
    this.circularLeading = false,
    this.textLines = 2,
    this.showTrailing = true,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;
  final double leadingSize;
  final bool circularLeading;
  final int textLines;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      child: Padding(
        padding: padding,
        child: Column(
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == itemCount - 1 ? 0 : AppSpacing.cardGap,
              ),
              child: _SkeletonListCard(
                leadingSize: leadingSize,
                circularLeading: circularLeading,
                textLines: textLines,
                showTrailing: showTrailing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({
    super.key,
    this.leadingSize = 64,
    this.circularLeading = false,
    this.textLines = 2,
    this.showTrailing = true,
  });

  final double leadingSize;
  final bool circularLeading;
  final int textLines;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      child: _SkeletonListCard(
        leadingSize: leadingSize,
        circularLeading: circularLeading,
        textLines: textLines,
        showTrailing: showTrailing,
      ),
    );
  }
}

class AppSkeletonImage extends StatelessWidget {
  const AppSkeletonImage({
    super.key,
    required this.height,
    this.borderRadius = 12,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      child: Bone(
        height: height,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      ),
    );
  }
}

class AppSkeletonPanel extends StatelessWidget {
  const AppSkeletonPanel({super.key, this.rowCount = 3});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Bone.text(words: 3),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < rowCount; index++) ...[
              Row(
                children: const [
                  Expanded(child: Bone.text(words: 2)),
                  SizedBox(width: AppSpacing.md),
                  Bone.text(words: 1),
                ],
              ),
              if (index != rowCount - 1) const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class AppSkeletonDashboard extends StatelessWidget {
  const AppSkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var row = 0; row < 2; row++) ...[
            Row(
              children: [
                Expanded(child: _MetricSkeleton(key: ValueKey('left-$row'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _MetricSkeleton(key: ValueKey('right-$row'))),
              ],
            ),
            if (row == 0) const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
          const AppSkeletonPanel(rowCount: 4),
          const SizedBox(height: AppSpacing.sectionGap),
          const AppSkeletonPanel(rowCount: 3),
        ],
      ),
    );
  }
}

class AppSkeletonForm extends StatelessWidget {
  const AppSkeletonForm({super.key, this.fieldCount = 3});

  final int fieldCount;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (var index = 0; index < fieldCount; index++) ...[
            const Bone.text(words: 2),
            const SizedBox(height: AppSpacing.xs),
            const Bone(
              height: 52,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const Bone.button(height: 48, words: 2),
        ],
      ),
    );
  }
}

class _SkeletonListCard extends StatelessWidget {
  const _SkeletonListCard({
    required this.leadingSize,
    required this.circularLeading,
    required this.textLines,
    required this.showTrailing,
  });

  final double leadingSize;
  final bool circularLeading;
  final int textLines;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          if (circularLeading)
            Bone.circle(size: leadingSize)
          else
            Bone.square(
              size: leadingSize,
              borderRadius: BorderRadius.circular(12),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Bone.text(words: 3),
                for (var index = 0; index < textLines; index++) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Bone.text(words: index == textLines - 1 ? 2 : 4),
                ],
                const SizedBox(height: AppSpacing.xs),
                const Bone.button(height: 22, words: 1),
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: AppSpacing.sm),
            const Bone.icon(),
          ],
        ],
      ),
    );
  }
}

class _MetricSkeleton extends StatelessWidget {
  const _MetricSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.border),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone.icon(size: 24),
          SizedBox(height: AppSpacing.sm),
          Bone.text(words: 1),
          SizedBox(height: AppSpacing.xs),
          Bone.text(words: 2),
        ],
      ),
    );
  }
}
