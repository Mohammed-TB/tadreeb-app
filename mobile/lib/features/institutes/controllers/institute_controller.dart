import 'package:flutter/foundation.dart';
import '../models/institute_model.dart';
import '../services/institute_service.dart';

class InstituteController extends ChangeNotifier {
  final InstituteService _instituteService;

  InstituteController(this._instituteService);

  List<InstituteModel> _institutes = [];
  int _currentPage = 0;
  int _totalPages = 1;
  int _total = 0;
  int _requestId = 0;
  String _searchQuery = '';
  bool _hasLoaded = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<InstituteModel> get institutes => _institutes;
  int get total => _total;
  bool get hasMore => _currentPage < _totalPages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  Future<void> getInstitutes({
    String? search,
    bool loadMore = false,
    bool forceRefresh = false,
  }) async {
    final normalizedSearch = (search ?? _searchQuery).trim();
    final searchChanged = normalizedSearch != _searchQuery;

    if (loadMore &&
        (searchChanged || _isLoading || _isLoadingMore || !hasMore)) {
      return;
    }
    if (!loadMore &&
        !searchChanged &&
        !forceRefresh &&
        (_hasLoaded || _isLoading)) {
      return;
    }

    final requestId = ++_requestId;
    final requestedPage = loadMore ? _currentPage + 1 : 1;
    _searchQuery = normalizedSearch;
    if (!loadMore) {
      _isLoading = true;
      _isLoadingMore = false;
      _currentPage = 0;
      _totalPages = 1;
      _total = 0;
      _institutes = [];
    } else {
      _isLoadingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _instituteService.getInstitutes(
        search: normalizedSearch,
        page: requestedPage,
        limit: 12,
      );
      if (requestId != _requestId) return;

      _institutes = loadMore
          ? [..._institutes, ...result.institutes]
          : result.institutes;
      _currentPage = result.page;
      _totalPages = result.totalPages;
      _total = result.total;
      _hasLoaded = true;
    } catch (error) {
      if (requestId != _requestId) return;
      _errorMessage = error.toString();
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }
}
