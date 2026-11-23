import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:project_1/features/institutes/controllers/institute_controller.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_skeletons.dart';
import '../../courses/models/course_model.dart';
import '../../courses/services/course_service.dart';
import '../../courses/widgets/course_card.dart';
import '../../institutes/models/institute_model.dart';

class InstituteDetailsScreen extends StatefulWidget {
  const InstituteDetailsScreen({super.key, required this.institute});

  final InstituteModel institute;

  @override
  State<InstituteDetailsScreen> createState() => _InstituteDetailsScreenState();
}

class _InstituteDetailsScreenState extends State<InstituteDetailsScreen> {
  CoursesResponse? _courses;
  bool _isCoursesLoading = true;
  Object? _coursesError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCourses(forceRefresh: true);
    });
  }

  Future<void> _loadCourses({
    bool forceRefresh = false,
    bool showRefreshError = false,
  }) async {
    final service = context.read<CourseService>();
    const limit = 50;

    try {
      final cached = await service.getCachedCourses(
        instituteId: widget.institute.id,
        limit: limit,
      );
      if (cached != null && mounted) {
        setState(() {
          _courses = cached;
          _isCoursesLoading = false;
          _coursesError = null;
        });
      }
    } catch (error) {
      debugPrint('Unable to read cached institute courses: $error');
    }

    try {
      final result = await service.loadCourses(
        instituteId: widget.institute.id,
        limit: limit,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      if (_courses == null || result.changed) {
        setState(() => _courses = result.data);
      }
      if (_coursesError != null) {
        setState(() => _coursesError = null);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _coursesError = error);
      if (_courses == null || showRefreshError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('تعذر تحديث دورات المعهد: $error')),
          );
      }
    } finally {
      if (mounted && _isCoursesLoading) {
        setState(() => _isCoursesLoading = false);
      }
    }
  }

  Future<void> _refresh() =>
      _loadCourses(forceRefresh: true, showRefreshError: true);

  @override
  Widget build(BuildContext context) {
    final institute = widget.institute;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 270,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                institute.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHero(institute),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              sliver: SliverList.list(
                children: [
                  _buildAboutCard(institute),
                  const SizedBox(height: AppSpacing.sectionGap),
                  _buildCoursesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(InstituteModel institute) {
    final image = institute.imageUrl;
    final isNetworkImage =
        image != null &&
        (image.startsWith('http://') || image.startsWith('https://'));

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isNetworkImage)
          CachedNetworkImage(
            imageUrl: image,
            fit: BoxFit.cover,
            placeholder: (_, _) => _buildHeroPlaceholder(),
            errorWidget: (_, _, _) => _buildHeroPlaceholder(),
          )
        else
          _buildHeroPlaceholder(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0x00000000), Color(0xD9000000)],
              stops: [0, 0.42, 1],
            ),
          ),
        ),
        PositionedDirectional(
          start: AppSpacing.md,
          end: AppSpacing.md,
          bottom: 62,
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  institute.address.isEmpty
                      ? 'الموقع غير محدد'
                      : institute.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        PositionedDirectional(
          start: AppSpacing.md,
          end: AppSpacing.md,
          bottom: 88,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  institute.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPlaceholder() {
    return Container(
      color: AppColors.primaryDark,
      alignment: Alignment.center,
      child: Icon(
        Icons.apartment_rounded,
        size: 76,
        color: Colors.white.withValues(alpha: 0.78),
      ),
    );
  }

  Widget _buildAboutCard(InstituteModel institute) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('عن المعهد', style: AppTypography.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'نشط',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            institute.description?.trim().isNotEmpty == true
                ? institute.description!.trim()
                : 'لا توجد نبذة تعريفية مضافة لهذا المعهد حتى الآن.',
            style: AppTypography.bodyMedium.copyWith(
              color: institute.description?.trim().isNotEmpty == true
                  ? AppColors.textSecondary
                  : AppColors.textHint,
              height: 1.65,
            ),
          ),
          if (institute.phone.isNotEmpty ||
              (institute.email?.isNotEmpty ?? false)) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            if (institute.phone.isNotEmpty)
              _buildInfoRow(
                icon: Icons.phone_outlined,
                label: 'رقم التواصل',
                value: institute.phone,
                textDirection: TextDirection.ltr,
              ),
            if (institute.phone.isNotEmpty &&
                (institute.email?.isNotEmpty ?? false))
              const SizedBox(height: AppSpacing.sm),
            if (institute.email?.isNotEmpty ?? false)
              _buildInfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'البريد الإلكتروني',
                value: institute.email!,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    TextDirection? textDirection,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                textDirection: textDirection,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesSection() {
    final courses = (_courses?.courses ?? const <CourseModel>[])
        .where((course) => course.instituteId == widget.institute.id)
        .toList(growable: false);
    final controller = context.watch<InstituteController>();
    final institutes = controller.institutes;

    final title = Row(
      children: [
        const Icon(
          Icons.auto_stories_rounded,
          color: AppColors.primary,
          size: 21,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text('الدورات المتاحة', style: AppTypography.titleMedium),
        ),
        if (_courses != null)
          Text(
            '${courses.length} دورة',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );

    if (_isCoursesLoading && _courses == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: AppSpacing.sm),
          const AppSkeletonList(itemCount: 2, leadingSize: 112, textLines: 2),
        ],
      );
    }

    if (_coursesError != null && _courses == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: AppSpacing.sm),
          _buildStatusCard(
            icon: Icons.cloud_off_rounded,
            message: 'تعذر تحميل دورات المعهد.',
            action: TextButton.icon(
              onPressed: () =>
                  _loadCourses(forceRefresh: true, showRefreshError: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    if (courses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: AppSpacing.sm),
          _buildStatusCard(
            icon: Icons.school_outlined,
            message: 'لا توجد دورات منشورة لهذا المعهد حاليًا.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 305,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: 2,
            ),
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final course = courses[index];
              return CourseCard(
                course: course,
                institutes: institutes,
                width: 230,
                height: 112,
                showDetailsCourse: () =>
                    context.push('/course-details', extra: course),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xs),
            action,
          ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
