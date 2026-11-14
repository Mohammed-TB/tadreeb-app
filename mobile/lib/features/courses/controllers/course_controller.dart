import 'package:flutter/foundation.dart';

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
  CourseController(this._courseService);

  final CourseService _courseService;

  // Courses
  List<CourseModel> _courses = [];
  List<CourseModel> get courses => _courses;
  List<String> get availableCategories {
    final available =
        _courses
            .map((course) => course.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['الكل', ...available];
  }

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

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;

  bool get hasMore => _currentPage < _totalPages;

  // Search, category and sort
  String _searchQuery = '';
  String? _category;
  CourseSortOption _sortOption = CourseSortOption.none;

  String? get selectedCategory => _category;
  CourseSortOption get sortOption => _sortOption;
  bool get hasActiveFilter => _sortOption != CourseSortOption.none;

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
      return course.price < 20000 &&
          (_category == null || course.category.trim() == _category);
    }).toList();

    _applySorting(list);
    return list;
  }

  // GET Courses
  Future<void> getCourses({bool forceRefresh = false}) async {
    if (_isLoading || (_hasFetched && !forceRefresh)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;

    notifyListeners();

    try {
      final result = await _courseService.getCourses(page: 1, limit: _limit);

      _courses = result.courses;
      _currentPage = result.pagination.page;
      _totalPages = result.pagination.totalPages;

      _hasFetched = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      final result = await _courseService.getCourses(
        page: nextPage,
        limit: _limit,
      );

      _courses.addAll(result.courses);

      _currentPage = result.pagination.page;
      _totalPages = result.pagination.totalPages;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
