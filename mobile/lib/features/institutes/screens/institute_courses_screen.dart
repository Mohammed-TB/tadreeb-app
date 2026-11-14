import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/button.dart';
import '../../../core/widgets/search.dart';
import '../../courses/models/course_model.dart';
import '../../courses/services/course_service.dart';
import '../widgets/courses/institute_course_card.dart';
import '../widgets/courses/institute_courses_header.dart';
import 'add_institute_course_screen.dart';

/// شاشة إدارة دورات المعهد بتصميم هادئ ومريح مطابق 100% لشاشة الحجوزات ونظام التصميم الموحد
class InstituteCoursesScreen extends StatefulWidget {
  const InstituteCoursesScreen({super.key});

  @override
  State<InstituteCoursesScreen> createState() => _InstituteCoursesScreenState();
}

class _InstituteCoursesScreenState extends State<InstituteCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CourseModel> _courses = [];
  CourseStatus? _statusFilter;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// جلب دورات المعهد من الـ Backend
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await context.read<CourseService>().getMyCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل الدورات: $error';
        _isLoading = false;
      });
    }
  }

  /// فتح شاشة إضافة دورة جديدة
  Future<void> _openAddCourse() async {
    final created = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddInstituteCourseScreen(),
      ),
    );

    if (created == true && mounted) {
      _showMessage('تم إنشاء الدورة بنجاح');
      _loadCourses();
    }
  }

  /// نشر الدورة المسودة
  Future<void> _publishCourse(CourseModel course) async {
    if (course.id == null) return;

    final confirmed = await _showConfirmDialog(
      title: 'تأكيد نشر الدورة',
      message: 'هل تريد نشر دورة "${course.title}" وإتاحتها لتسجيل الطلاب؟',
      confirmText: 'نشر الدورة',
      confirmVariant: AppButtonVariant.accent,
    );
    if (!confirmed || !mounted) return;

    try {
      await context.read<CourseService>().publishCourse(course.id!);
      if (!mounted) return;
      _showMessage('تم نشر الدورة بنجاح');
      _loadCourses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('تعذر نشر الدورة: $error');
    }
  }

  /// إغلاق التسجيل في دورة
  Future<void> _closeCourse(CourseModel course) async {
    if (course.id == null) return;

    final confirmed = await _showConfirmDialog(
      title: 'إغلاق التسجيل',
      message:
          'هل تريد إغلاق التسجيل في دورة "${course.title}"؟ لن يتمكن الطلاب الجدد من التسجيل.',
      confirmText: 'إغلاق التسجيل',
      confirmVariant: AppButtonVariant.outline,
    );
    if (!confirmed || !mounted) return;

    try {
      await context.read<CourseService>().closeCourse(course.id!);
      if (!mounted) return;
      _showMessage('تم إغلاق التسجيل في الدورة بنجاح');
      _loadCourses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('تعذر إغلاق الدورة: $error');
    }
  }

  /// حذف دورة مسودة
  Future<void> _deleteCourse(CourseModel course) async {
    if (course.id == null) return;

    final confirmed = await _showConfirmDialog(
      title: 'حذف مسودة الدورة',
      message:
          'هل أنت متأكد من حذف مسودة "${course.title}"؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'تأكيد الحذف',
      confirmVariant: AppButtonVariant.outline,
    );
    if (!confirmed || !mounted) return;

    try {
      await context.read<CourseService>().deleteCourse(course.id!);
      if (!mounted) return;
      _showMessage('تم حذف مسودة الدورة بنجاح');
      _loadCourses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('تعذر حذف الدورة: $error');
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required AppButtonVariant confirmVariant,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(message, style: AppTypography.bodyMedium),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: Button(
                        text: 'إلغاء',
                        variant: AppButtonVariant.outline,
                        height: 40,
                        onTap: () => Navigator.pop(dialogContext, false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Button(
                        text: confirmText,
                        variant: confirmVariant,
                        height: 40,
                        onTap: () => Navigator.pop(dialogContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  List<CourseModel> get _filteredCourses {
    final query = _searchController.text.trim().toLowerCase();
    return _courses.where((course) {
      final matchesQuery = query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.category.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == null || course.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  int _countFor(CourseStatus? status) {
    if (status == null) return _courses.length;
    return _courses.where((c) => c.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final courses = _filteredCourses;
    final hasActiveFilters =
        _searchController.text.trim().isNotEmpty || _statusFilter != null;

    final filters = <(String, CourseStatus?)>[
      ('الكل (${_countFor(null)})', null),
      ('منشورة (${_countFor(CourseStatus.published)})', CourseStatus.published),
      ('مسودة (${_countFor(CourseStatus.draft)})', CourseStatus.draft),
      ('مغلقة (${_countFor(CourseStatus.closed)})', CourseStatus.closed),
      ('مكتملة (${_countFor(CourseStatus.completed)})', CourseStatus.completed),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddCourse,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'إضافة دورة',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadCourses,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. ترويسة الصفحة الموحدة
              SliverToBoxAdapter(
                child: const InstituteCoursesHeader(),
              ),

              // 2. المحتوى الداخلي المريح والمنسق
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // مكون البحث الموحد للتطبيق Search
                    Search(
                      controller: _searchController,
                      hinText: 'ابحث باسم الدورة أو التصنيف...',
                      isShowFilter: false,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // شرائح الفلترة الذكية الموحدة
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: filters.map((filter) {
                          final isSelected = _statusFilter == filter.$2;
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: AppSpacing.xs,
                            ),
                            child: ChoiceChip(
                              label: Text(filter.$1),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = filter.$2),
                              selectedColor: AppColors.primaryLight,
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 1.2 : 1.0,
                              ),
                              labelStyle: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // حالات التحميل والخطأ والفارغة وقائمة الدورات
                    if (_isLoading && _courses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.xxxl,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (_errorMessage != null && _courses.isEmpty)
                      _buildErrorState()
                    else if (courses.isEmpty)
                      _buildEmptyState(hasActiveFilters)
                    else
                      ...courses.map(
                        (course) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm,
                          ),
                          child: InstituteCourseCard(
                            course: course,
                            onPublish: () => _publishCourse(course),
                            onClose: () => _closeCourse(course),
                            onDelete: () => _deleteCourse(course),
                          ),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xxxl + 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'تعذر تحميل الدورات',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _errorMessage ?? 'حدث خطأ غير متوقع',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Button(
            text: 'إعادة المحاولة',
            variant: AppButtonVariant.accent,
            icon: Icons.refresh_rounded,
            width: 160,
            height: 40,
            onTap: _loadCourses,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool hasActiveFilters) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.field,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasActiveFilters
                  ? Icons.search_off_rounded
                  : Icons.school_outlined,
              size: 32,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasActiveFilters
                ? 'لا توجد نتائج مطابقة'
                : 'لم تقم بإضافة أي دورة بعد',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasActiveFilters
                ? 'جرّب تغيير كلمات البحث أو اختيار حالة أخرى.'
                : 'ابدأ بإضافة أول برنامج تدريبي لمعهدك واستقبل تسجيلات الطلاب فوراً.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasActiveFilters)
            Button(
              text: 'إلغاء الفلترة',
              variant: AppButtonVariant.outline,
              width: 140,
              height: 38,
              onTap: () {
                _searchController.clear();
                setState(() => _statusFilter = null);
              },
            )
          else
            Button(
              text: 'إضافة دورة جديدة',
              variant: AppButtonVariant.accent,
              icon: Icons.add_rounded,
              width: 170,
              height: 42,
              onTap: _openAddCourse,
            ),
        ],
      ),
    );
  }
}
