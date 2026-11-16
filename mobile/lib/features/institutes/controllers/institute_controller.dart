import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_service.dart';
import '../../../core/state/app_data_change_bus.dart';
import '../models/institute_model.dart';
import '../services/institute_service.dart';

class InstituteController extends ChangeNotifier {
  final InstituteService _instituteService;

  InstituteController(
    this._instituteService, {
    RealtimeService? realtimeService,
    AppDataChangeBus? dataChangeBus,
  }) {
    _realtimeSubscription = realtimeService?.events.listen(_onRealtimeEvent);
    _dataChangeSubscription = dataChangeBus?.changes.listen(
      _onLocalDataChange,
    );
  }

  List<InstituteModel> _institutes = [];
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  StreamSubscription<AppDataChange>? _dataChangeSubscription;
  Timer? _realtimeRefreshTimer;
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

  Future<bool> loadCachedInstitutes({String? search}) async {
    final normalizedSearch = (search ?? _searchQuery).trim();
    final cached = await _instituteService.getCachedInstitutes(
      search: normalizedSearch,
      page: 1,
      limit: 12,
    );
    if (cached == null) return false;

    final changed = !_sameInstitutes(_institutes, cached.institutes) ||
        _currentPage != cached.page ||
        _totalPages != cached.totalPages ||
        _total != cached.total;
    _searchQuery = normalizedSearch;
    _institutes = cached.institutes;
    _currentPage = cached.page;
    _totalPages = cached.totalPages;
    _total = cached.total;
    _hasLoaded = true;
    _errorMessage = null;
    if (changed) notifyListeners();
    return true;
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (event.name != 'syncRequired' || event.role != 'student') return;

    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(
      const Duration(milliseconds: 200),
      () => unawaited(getInstitutes(forceRefresh: true)),
    );
  }

  void _onLocalDataChange(AppDataChange change) {
    if (change.domain != AppDataDomain.institutes) return;

    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(getInstitutes(forceRefresh: true)),
    );
  }

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
    final hadVisibleInstitutes = _institutes.isNotEmpty;
    _searchQuery = normalizedSearch;
    if (!loadMore) {
      _isLoading = true;
      _isLoadingMore = false;
      if (searchChanged) {
        _currentPage = 0;
        _totalPages = 1;
        _total = 0;
        _institutes = [];
      }
    } else {
      _isLoadingMore = true;
    }
    final hadError = _errorMessage != null;
    _errorMessage = null;
    final showLoadingState =
        loadMore || !hadVisibleInstitutes || searchChanged;
    if (showLoadingState || hadError) notifyListeners();
    var shouldNotify = hadError;
    var loadedCachedPage = false;

    try {
      if (!loadMore && (searchChanged || _institutes.isEmpty)) {
        final cached = await _instituteService.getCachedInstitutes(
          search: normalizedSearch,
          page: 1,
          limit: 12,
        );
        if (requestId != _requestId) return;
        if (cached != null) {
          shouldNotify |= !_sameInstitutes(_institutes, cached.institutes) ||
              _currentPage != cached.page ||
              _totalPages != cached.totalPages ||
              _total != cached.total;
          _institutes = cached.institutes;
          _currentPage = cached.page;
          _totalPages = cached.totalPages;
          _total = cached.total;
          _hasLoaded = true;
          if (shouldNotify) notifyListeners();
        }
      } else if (loadMore) {
        final cached = await _instituteService.getCachedInstitutes(
          search: normalizedSearch,
          page: requestedPage,
          limit: 12,
        );
        if (requestId != _requestId) return;
        if (cached != null) {
          loadedCachedPage = true;
          _replacePage(requestedPage, cached.institutes);
          _currentPage = cached.page;
          _totalPages = cached.totalPages;
          _total = cached.total;
          notifyListeners();
        }
      }

      final result = await _instituteService.loadInstitutes(
        search: normalizedSearch,
        page: requestedPage,
        limit: 12,
        forceRefresh: forceRefresh,
      );
      if (requestId != _requestId) return;

      if (!loadMore &&
          !_sameInstitutes(_institutes, result.data.institutes)) {
        _replacePage(requestedPage, result.data.institutes);
        shouldNotify = true;
      } else if (loadMore && (!loadedCachedPage || result.changed)) {
        _replacePage(requestedPage, result.data.institutes);
        shouldNotify = true;
      }
      shouldNotify |= _currentPage != result.data.page ||
          _totalPages != result.data.totalPages ||
          _total != result.data.total;
      _currentPage = result.data.page;
      _totalPages = result.data.totalPages;
      _total = result.data.total;
      _hasLoaded = true;
    } catch (error) {
      if (requestId != _requestId) return;
      shouldNotify |= _errorMessage != error.toString();
      _errorMessage = error.toString();
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        _isLoadingMore = false;
        if (showLoadingState || shouldNotify) notifyListeners();
      }
    }
  }

  bool _sameInstitutes(
    List<InstituteModel> first,
    List<InstituteModel> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      final a = first[index];
      final b = second[index];
      if (a.id != b.id ||
          a.ownerUserId != b.ownerUserId ||
          a.name != b.name ||
          a.address != b.address ||
          a.phone != b.phone ||
          a.imageUrl != b.imageUrl ||
          a.description != b.description ||
          a.email != b.email ||
          a.status != b.status) {
        return false;
      }
    }
    return true;
  }

  void _replacePage(int page, List<InstituteModel> institutes) {
    if (page == 1) {
      _institutes = institutes;
      return;
    }

    final startIndex = (page - 1) * 12;
    _institutes = [..._institutes.take(startIndex), ...institutes];
  }

  @override
  void dispose() {
    _realtimeRefreshTimer?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_dataChangeSubscription?.cancel());
    super.dispose();
  }
}
