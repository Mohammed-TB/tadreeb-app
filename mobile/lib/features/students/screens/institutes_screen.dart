import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_skeletons.dart';
import '../../favorites/controllers/favorite_controller.dart';
import '../../institutes/controllers/institute_controller.dart';
import '../../institutes/models/institute_model.dart';
import '../widgets/institute_card.dart';

class InstitutesScreen extends StatefulWidget {
  const InstitutesScreen({super.key});

  @override
  State<InstitutesScreen> createState() => _InstitutesScreenState();
}

class _InstitutesScreenState extends State<InstitutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InstituteController>().getInstitutes();
      context.read<FavoriteController>().loadFavorites();
    });
  }

  void _loadNextPage() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 320) {
      return;
    }
    context.read<InstituteController>().getInstitutes(loadMore: true);
  }

  void _onSearchChanged(String value) {
    context.read<InstituteController>().setSearchQuery(value);
  }

  Future<void> _refresh() {
    return context.read<InstituteController>().getInstitutes(
      forceRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InstituteController>();
    final favorites = context.watch<FavoriteController>();

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

        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: _buildResults(controller, favorites),
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

  Widget _buildResults(
    InstituteController controller,
    FavoriteController favorites,
  ) {
    if (controller.isLoading && controller.institutes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          AppSkeletonList(
            itemCount: 3,
            padding: EdgeInsets.all(AppSpacing.md),
            leadingSize: 86,
            textLines: 2,
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

    final institutes = controller.filteredInstitutes;

    if (institutes.isEmpty) {
      final hasSearch = _searchController.text.trim().isNotEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _buildMessage(
            icon: Icons.apartment_outlined,
            title: hasSearch ? 'لا توجد نتائج مطابقة' : 'لا توجد معاهد متاحة',
            message: hasSearch
                ? controller.hasMore
                      ? 'لم تظهر نتائج ضمن المعاهد المحملة بعد.'
                      : 'جرّب البحث بكلمات مختلفة.'
                : 'ستظهر هنا المعاهد النشطة عند توفرها.',
            actionLabel: hasSearch && controller.hasMore
                ? 'تحميل المزيد من المعاهد'
                : null,
            onAction: hasSearch && controller.hasMore
                ? () => controller.getInstitutes(loadMore: true)
                : null,
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
          institutes.length +
          (controller.hasMore || controller.errorMessage != null ? 1 : 0),
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.cardGap),
      itemBuilder: (context, index) {
        if (index == institutes.length) {
          if (controller.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.cardGap),
              child: AppSkeletonCard(
                leadingSize: 56,
                textLines: 1,
                showTrailing: false,
              ),
            );
          }
          if (controller.errorMessage != null) {
            return TextButton.icon(
              onPressed: () => controller.getInstitutes(loadMore: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تعذر تحميل المزيد، حاول مجددًا'),
            );
          }
          return const SizedBox(height: AppSpacing.md);
        }

        final institute = institutes[index];
        return InstituteCard(
          institute: institute,
          layout: InstituteCardLayout.horizontal,
          width: double.infinity,
          imageHeight: 96,
          showDetailsButton: false,
          onTap: () => context.push('/institute-details', extra: institute),
          isFavorite: favorites.isInstituteFavorite(institute.id),
          isFavoriteBusy: favorites.isInstituteSaving(institute.id),
          onFavoriteTap: favorites.canToggleFavorites
              ? () => _toggleFavorite(institute)
              : null,
        );
      },
    );
  }

  Future<void> _toggleFavorite(InstituteModel institute) async {
    try {
      await context.read<FavoriteController>().toggleInstitute(institute);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('تعذر تحديث المفضلة: $error')));
    }
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

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPage)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }
}
