import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_service.dart';
import '../../../core/state/app_data_change_bus.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

enum CourseSortOption {
  none,
  priceHighToLow,
  priceLowToHigh,
  dateNewest,
  dateStartingSoon;

  String get label {
    switch (this) {
      case CourseSortOption.none:
        return 'الافتراضي';
      case CourseSortOption.priceHighToLow:
        return 'الأعلى سعراً';
      case CourseSortOption.priceLowToHigh:
        return 'الأقل سعراً';
      case CourseSortOption.dateNewest:
        return 'الأحدث إضافة';
      case CourseSortOption.dateStartingSoon:
        return 'الأقرب بدءاً';
    }
  }
}

class CourseController extends ChangeNotifier {
  CourseController(
    this._courseService, {
    RealtimeService? realtimeService,
    AppDataChangeBus? dataChangeBus,
  }) {
    _realtimeSubscription = realtimeService?.events.listen(_onRealtimeEvent);
    _dataChangeSubscription = dataChangeBus?.changes.listen(_onLocalDataChange);
  }

  final CourseService _courseService;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  StreamSubscription<AppDataChange>? _dataChangeSubscription;
  Timer? _realtimeRefreshTimer;

  // Courses
  List<CourseModel> _courses = [];
  List<CourseModel> get courses => _courses;
  List<String> _categories = [];
  List<String> get availableCategories => ['الكل', ..._categories];
  bool _hasLoadedCategories = false;
  Future<void>? _categoriesLoad;
  String? _categoriesErrorMessage;
  String? get categoriesErrorMessage => _categoriesErrorMessage;

  List<CourseModel> get filteredCourses {
    final query = _searchQuery.toLowerCase();
    final list = _courses.where((course) {
      if (_category != null && course.category.trim() != _category) {
        return false;
      }
      if (query.isEmpty) return true;

      final searchableText =
          '${course.title} ${course.description} ${course.category} ${course.location}'
              .toLowerCase();
      return searchableText.contains(query);
    }).toList();

    _applySorting(list);
    return list;
  }

  // Loading and errors
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasFetched = false;
  bool _refreshRequested = false;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;

  bool get hasMore => _currentPage < _totalPages;

  Future<void> loadCategories({bool forceRefresh = false}) {
    if (_hasLoadedCategories && !forceRefresh) return Future<void>.value();
    final inFlight = _categoriesLoad;
    if (inFlight != null) return inFlight;

    final request = _fetchCategories(forceRefresh: forceRefresh);
    _categoriesLoad = request;
    return request.whenComplete(() {
      if (identical(_categoriesLoad, request)) _categoriesLoad = null;
    });
  }

  Future<void> _fetchCategories({required bool forceRefresh}) async {
    try {
      final categories = await _courseService.getCourseCategories(
        forceRefresh: forceRefresh,
      );
      final selectedCategory = _category;
      _categories = categories;
      if (selectedCategory != null && !categories.contains(selectedCategory)) {
        _category = null;
      }
      _hasLoadedCategories = true;
      _categoriesErrorMessage = null;
    } catch (error) {
      _categoriesErrorMessage = error.toString();
    } finally {
      notifyListeners();
    }
  }

  // Search, category and sort
  String _searchQuery = '';
  String? _category;
  CourseSortOption _sortOption = CourseSortOption.none;

  String? get selectedCategory => _category;
  CourseSortOption get sortOption => _sortOption;
  bool get hasActiveFilter => _sortOption != CourseSortOption.none;

  Future<bool> loadCachedCourses() async {
    final cached = await _courseService.getCachedCourses(
      page: 1,
      limit: _limit,
    );
    if (cached == null) return false;

    _courses = cached.courses;
    _currentPage = cached.pagination.page;
    _totalPages = cached.pagination.totalPages;
    _hasFetched = true;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void setSearchQuery(String value) {
    final query = value.trim();
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    final normalizedCategory = category.trim();
    final selected = normalizedCategory == 'الكل' ? null : normalizedCategory;
    if (_category == selected) return;
    _category = selected;
    notifyListeners();
  }

  void setSortOption(CourseSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    notifyListeners();
  }

  void resetSortOption() {
    if (_sortOption == CourseSortOption.none) return;
    _sortOption = CourseSortOption.none;
    notifyListeners();
  }

  void _applySorting(List<CourseModel> list) {
    switch (_sortOption) {
      case CourseSortOption.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case CourseSortOption.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case CourseSortOption.dateNewest:
        list.sort((a, b) {
          final dateA = a.createdAt ?? a.startDate;
          final dateB = b.createdAt ?? b.startDate;
          return dateB.compareTo(dateA);
        });
        break;
      case CourseSortOption.dateStartingSoon:
        list.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case CourseSortOption.none:
        break;
    }
  }

  // الدورات المميزة
  List<CourseModel> get featuredCourses {
    final list = courses.where((course) {
      return course.enrolledCount > course.capacity / course.capacity / 3 / 5 &&
          (_category == null || course.category.trim() == _category);
    }).toList();

    _applySorting(list);
    return list;
  }

  // GET Courses
  Future<void> getCourses({bool forceRefresh = false}) async {
    unawaited(loadCategories(forceRefresh: forceRefresh));
    if (_isLoading) {
      if (forceRefresh) _refreshRequested = true;
      return;
    }
    if (_hasFetched && !forceRefresh) {
      return;
    }

    final hadCourses = _courses.isNotEmpty;
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    if (!hadCourses) notifyListeners();
    var shouldNotify = !hadCourses;

    try {
      if (_courses.isEmpty) await loadCachedCourses();
      final result = await _courseService.loadCourses(
        page: 1,
        limit: _limit,
        forceRefresh: forceRefresh,
      );

      if (_courses.isEmpty || result.changed) {
        _courses = result.data.courses;
        shouldNotify = true;
      }
      _currentPage = result.data.pagination.page;
      _totalPages = result.data.pagination.totalPages;

      _hasFetched = true;
      if (_errorMessage != null) shouldNotify = true;
      _errorMessage = null;
    } catch (e) {
      if (_errorMessage != e.toString()) shouldNotify = true;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      if (shouldNotify || _courses.isEmpty) notifyListeners();
      if (_refreshRequested) {
        _refreshRequested = false;
        unawaited(getCourses(forceRefresh: true));
      }
    }
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    final isStudentReconnect =
        event.name == 'syncRequired' && event.role == 'student';
    final isCourseChange = {
      'coursePublished',
      'courseUpdated',
      'courseUnpublished',
      'seatAvailabilityUpdated',
    }.contains(event.name);
    if ((!isStudentReconnect && !isCourseChange) ||
        (isCourseChange && event.role != 'student')) {
      return;
    }

    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(getCourses(forceRefresh: true)),
    );
  }

  void _onLocalDataChange(AppDataChange change) {
    if (change.audience != AppDataAudience.student ||
        (change.domain != AppDataDomain.courses &&
            change.domain != AppDataDomain.reservations)) {
      return;
    }

    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(getCourses(forceRefresh: true)),
    );
  }

  // Load More Courses
  Future<void> loadMoreCourses() async {
    if (_isLoadingMore || !hasMore || _isLoading) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;

      final cached = await _courseService.getCachedCourses(
        page: nextPage,
        limit: _limit,
      );
      if (cached != null) {
        _replaceCoursePage(nextPage, cached);
        _currentPage = cached.pagination.page;
        _totalPages = cached.pagination.totalPages;
        notifyListeners();
      }

      final result = await _courseService.loadCourses(
        page: nextPage,
        limit: _limit,
      );

      if (cached == null || result.changed) {
        _replaceCoursePage(nextPage, result.data);
      }
      _currentPage = result.data.pagination.page;
      _totalPages = result.data.pagination.totalPages;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _replaceCoursePage(int page, CoursesResponse result) {
    final startIndex = (page - 1) * _limit;
    final existing = _courses.take(startIndex).toList();
    _courses = [...existing, ...result.courses];
  }

  @override
  void dispose() {
    _realtimeRefreshTimer?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_dataChangeSubscription?.cancel());
    super.dispose();
  }
}
