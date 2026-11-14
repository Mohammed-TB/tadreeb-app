import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../institutes/controllers/institute_controller.dart';
import '../../institutes/models/institute_model.dart';

class InstitutesScreen extends StatefulWidget {
  const InstitutesScreen({super.key});

  @override
  State<InstitutesScreen> createState() => _InstitutesScreenState();
}

class _InstitutesScreenState extends State<InstitutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InstituteController>().getInstitutes();
    });
  }

  void _loadNextPage() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 320) {
      return;
    }
    context.read<InstituteController>().getInstitutes(
      search: _searchController.text,
      loadMore: true,
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<InstituteController>().getInstitutes(search: value);
    });
  }

  Future<void> _refresh() {
    return context.read<InstituteController>().getInstitutes(
      search: _searchController.text,
      forceRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InstituteController>();

    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: _buildSearchField(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.apartment_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                controller.isLoading && controller.institutes.isEmpty
                    ? 'جاري تحميل المعاهد'
                    : '${controller.total} معهد متاح',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: _buildResults(controller),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'المعاهد',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Positioned(
                right: 4,
                child: Builder(
                  builder: (headerContext) => IconButton(
                    onPressed: () => Scaffold.of(headerContext).openDrawer(),
                    tooltip: 'فتح القائمة',
                    icon: const Icon(Icons.menu, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, value, child) {
        return TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ابحث باسم المعهد أو الموقع',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'مسح البحث',
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResults(InstituteController controller) {
    if (controller.isLoading && controller.institutes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ],
      );
    }

    if (controller.errorMessage != null && controller.institutes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _buildMessage(
            icon: Icons.cloud_off_rounded,
            title: 'تعذر تحميل المعاهد',
            message: controller.errorMessage!,
            actionLabel: 'إعادة المحاولة',
            onAction: _refresh,
          ),
        ],
      );
    }

    if (controller.institutes.isEmpty) {
      final hasSearch = _searchController.text.trim().isNotEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _buildMessage(
            icon: Icons.apartment_outlined,
            title: hasSearch ? 'لا توجد نتائج مطابقة' : 'لا توجد معاهد متاحة',
            message: hasSearch
                ? 'جرّب البحث بكلمات مختلفة.'
                : 'ستظهر هنا المعاهد النشطة عند توفرها.',
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount:
          controller.institutes.length +
          (controller.hasMore || controller.errorMessage != null ? 1 : 0),
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.cardGap),
      itemBuilder: (context, index) {
        if (index == controller.institutes.length) {
          if (controller.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          if (controller.errorMessage != null) {
            return TextButton.icon(
              onPressed: () => controller.getInstitutes(
                search: _searchController.text,
                loadMore: true,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تعذر تحميل المزيد، حاول مجددًا'),
            );
          }
          return const SizedBox(height: AppSpacing.md);
        }

        final institute = controller.institutes[index];
        return _InstituteListCard(
          institute: institute,
          onTap: () => _showInstituteDetails(institute),
        );
      },
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 46, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  void _showInstituteDetails(InstituteModel institute) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InstituteDetailsSheet(institute: institute),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_loadNextPage)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _InstituteListCard extends StatelessWidget {
  const _InstituteListCard({required this.institute, required this.onTap});

  final InstituteModel institute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = institute.imageUrl;
    final isNetworkImage =
        imageUrl != null &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 76,
                  height: 76,
                  color: AppColors.primaryLight,
                  child: isNetworkImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _InstitutePlaceholder(),
                        )
                      : const _InstitutePlaceholder(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            institute.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.textHint,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            institute.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (institute.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        institute.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'عرض بيانات المعهد',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstitutePlaceholder extends StatelessWidget {
  const _InstitutePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.apartment_rounded, size: 34, color: AppColors.primary),
    );
  }
}

class _InstituteDetailsSheet extends StatelessWidget {
  const _InstituteDetailsSheet({required this.institute});

  final InstituteModel institute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(institute.name, style: AppTypography.titleLarge),
            if (institute.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                institute.description!.trim(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _InstituteDetailRow(
              icon: Icons.location_on_outlined,
              text: institute.address,
            ),
            if (institute.phone.isNotEmpty)
              _InstituteDetailRow(
                icon: Icons.phone_outlined,
                text: institute.phone,
                textDirection: TextDirection.ltr,
              ),
            if (institute.email?.isNotEmpty == true)
              _InstituteDetailRow(
                icon: Icons.email_outlined,
                text: institute.email!,
                textDirection: TextDirection.ltr,
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstituteDetailRow extends StatelessWidget {
  const _InstituteDetailRow({
    required this.icon,
    required this.text,
    this.textDirection,
  });

  final IconData icon;
  final String text;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              textDirection: textDirection,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
