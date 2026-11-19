import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/realtime/realtime_service.dart';
import '../../../core/state/app_data_change_bus.dart';
import '../../courses/models/course_model.dart';
import '../../courses/services/course_service.dart';
import '../widgets/courses/course_action_confirmation_dialog.dart';
import '../widgets/courses/institute_courses_filter_section.dart';
import '../widgets/courses/institute_courses_header.dart';
import '../widgets/courses/institute_courses_list_section.dart';
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
  StreamSubscription<AppDataChange>? _dataChangeSubscription;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _dataChangeSubscription = context.read<AppDataChangeBus>().changes.listen(
      _onDataChange,
    );
    _realtimeSubscription = context.read<RealtimeService>().events.listen(
      _onRealtimeEvent,
    );
    _loadCourses();
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!mounted ||
        event.role != 'instituteOwner' ||
        event.name != 'seatAvailabilityUpdated') {
      return;
    }
    _loadCourses();
  }

  void _onDataChange(AppDataChange change) {
    if (!mounted ||
        change.audience != AppDataAudience.instituteOwner ||
        change.origin == AppDataChangeOrigin.courseManagement ||
        (change.domain != AppDataDomain.courses &&
            change.domain != AppDataDomain.reservations)) {
      return;
    }

    _loadCourses();
  }

  @override
  void dispose() {
    unawaited(_dataChangeSubscription?.cancel());
    unawaited(_realtimeSubscription?.cancel());
    _searchController.dispose();
    super.dispose();
  }

  void _notifyCourseChange() {
    context.read<AppDataChangeBus>().notifyChanged(
      AppDataDomain.courses,
      AppDataChangeOrigin.courseManagement,
      audience: AppDataAudience.instituteOwner,
    );
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
      MaterialPageRoute(builder: (context) => const AddInstituteCourseScreen()),
    );

    if (created == true && mounted) {
      _notifyCourseChange();
      _showMessage('تم إنشاء الدورة بنجاح');
      _loadCourses();
    }
  }

  Future<void> _editCourse(CourseModel course) async {
    if (course.status != CourseStatus.draft || course.id == null) {
      _showMessage('يمكن تعديل المسودات فقط');
      return;
    }

    final updated = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddInstituteCourseScreen(course: course),
      ),
    );

    if (updated == true && mounted) {
      _notifyCourseChange();
      _showMessage('تم تعديل المسودة بنجاح');
      _loadCourses();
    }
  }

  /// نشر الدورة المسودة
  Future<void> _publishCourse(CourseModel course) async {
    if (course.id == null) return;

    final confirmed = await CourseActionConfirmationDialog.show(
      context,
      title: 'تأكيد نشر الدورة',
      message: 'هل تريد نشر دورة "${course.title}" وإتاحتها لتسجيل الطلاب؟',
      confirmText: 'نشر الدورة',
    );
    if (!confirmed || !mounted) return;

    final changeBus = context.read<AppDataChangeBus>();
    try {
      await context.read<CourseService>().publishCourse(course.id!);
      changeBus.notifyChanged(
        AppDataDomain.courses,
        AppDataChangeOrigin.courseManagement,
        audience: AppDataAudience.instituteOwner,
      );
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

    final confirmed = await CourseActionConfirmationDialog.show(
      context,
      title: 'إغلاق التسجيل',
      message:
          'هل تريد إغلاق التسجيل في دورة "${course.title}"؟ لن يتمكن الطلاب الجدد من التسجيل.',
      confirmText: 'إغلاق التسجيل',
    );
    if (!confirmed || !mounted) return;

    final changeBus = context.read<AppDataChangeBus>();
    try {
      await context.read<CourseService>().closeCourse(course.id!);
      changeBus.notifyChanged(
        AppDataDomain.courses,
        AppDataChangeOrigin.courseManagement,
        audience: AppDataAudience.instituteOwner,
      );
      if (!mounted) return;
      _showMessage('تم إغلاق التسجيل في الدورة بنجاح');
      _loadCourses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('تعذر إغلاق الدورة: $error');
    }
  }

  Future<void> _reopenCourse(CourseModel course) async {
    if (course.id == null) return;

    final confirmed = await CourseActionConfirmationDialog.show(
      context,
      title: 'إعادة فتح التسجيل',
      message: 'هل تريد إعادة فتح التسجيل في دورة "${course.title}"؟',
      confirmText: 'إعادة الفتح',
    );
    if (!confirmed || !mounted) return;

    final changeBus = context.read<AppDataChangeBus>();
    try {
      await context.read<CourseService>().reopenCourse(course.id!);
      changeBus.notifyChanged(
        AppDataDomain.courses,
        AppDataChangeOrigin.courseManagement,
        audience: AppDataAudience.instituteOwner,
      );
      if (!mounted) return;
      _showMessage('تم إعادة فتح التسجيل في الدورة بنجاح');
      _loadCourses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('تعذر إعادة فتح الدورة: $error');
    }
  }

  /// حذف دورة مسودة
  Future<void> _deleteCourse(CourseModel course) async {
    if (course.id == null) return;

    final confirmed = await CourseActionConfirmationDialog.show(
      context,
      title: 'حذف مسودة الدورة',
      message:
          'هل أنت متأكد من حذف مسودة "${course.title}"؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'تأكيد الحذف',
    );
    if (!confirmed || !mounted) return;

    final changeBus = context.read<AppDataChangeBus>();
    try {
      await context.read<CourseService>().deleteCourse(course.id!);
      changeBus.notifyChanged(
        AppDataDomain.courses,
        AppDataChangeOrigin.courseManagement,
        audience: AppDataAudience.instituteOwner,
      );
      if (!mounted) return;
      _showMessage('تم حذف مسودة الدورة بنجاح');
      _loadCourses();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('تعذر حذف الدورة: $error');
    }
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
      final matchesQuery =
          query.isEmpty ||
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
          heroTag: 'institute-courses-add',
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
        body: Column(
          children: [
            const InstituteCoursesHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.md,
              ),
              child: InstituteCoursesFilterSection(
                searchController: _searchController,
                filters: filters,
                selectedStatus: _statusFilter,
                onStatusChanged: (status) =>
                    setState(() => _statusFilter = status),
                onSearchChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCourses,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xxxl + 40,
                  ),
                  child: InstituteCoursesListSection(
                    courses: courses,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    hasActiveFilters: hasActiveFilters,
                    onRetry: _loadCourses,
                    onClearFilters: () {
                      _searchController.clear();
                      setState(() => _statusFilter = null);
                    },
                    onAddCourse: _openAddCourse,
                    onEditCourse: _editCourse,
                    onPublishCourse: _publishCourse,
                    onCloseCourse: _closeCourse,
                    onReopenCourse: _reopenCourse,
                    onDeleteCourse: _deleteCourse,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
