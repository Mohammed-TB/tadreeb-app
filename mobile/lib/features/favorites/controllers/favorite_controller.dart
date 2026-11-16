import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_service.dart';
import '../../../core/state/app_data_change_bus.dart';
import '../../courses/models/course_model.dart';
import '../../institutes/models/institute_model.dart';
import '../models/favorite.model.dart';
import '../services/favorite.service.dart';

class FavoriteController extends ChangeNotifier {
  FavoriteController(
    this._favoriteService, {
    RealtimeService? realtimeService,
    AppDataChangeBus? dataChangeBus,
  }) {
    _realtimeSubscription = realtimeService?.events.listen(_onRealtimeEvent);
    _dataChangeSubscription = dataChangeBus?.changes.listen(
      _onLocalDataChange,
    );
  }

  final FavoriteService _favoriteService;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  StreamSubscription<AppDataChange>? _dataChangeSubscription;
  Timer? _realtimeRefreshTimer;

  List<CourseModel> _courses = [];
  List<InstituteModel> _institutes = [];
  final Map<String, _PendingFavorite> _pending = {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _refreshRequested = false;
  String? _errorMessage;

  List<CourseModel> get courses => List.unmodifiable(_courses);
  List<InstituteModel> get institutes => List.unmodifiable(_institutes);
  bool get isLoading => _isLoading;
  bool get canToggleFavorites => _hasLoaded;
  String? get errorMessage => _errorMessage;

  bool isCourseFavorite(String? id) =>
      id != null && _courses.any((course) => course.id == id);

  bool isInstituteFavorite(String id) =>
      _institutes.any((institute) => institute.id == id);

  bool isCourseSaving(String? id) =>
      id != null && (_pending['${FavoriteTargetType.course.name}:$id']?.saving ?? false);

  bool isInstituteSaving(String id) =>
      _pending['${FavoriteTargetType.institute.name}:$id']?.saving ?? false;

  Future<void> loadFavorites({bool forceRefresh = false}) async {
    if (_isLoading || _pending.isNotEmpty) {
      if (forceRefresh) _refreshRequested = true;
      return;
    }
    if (_hasLoaded && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _courses = await _favoriteService.getFavoriteCourses();
      _institutes = await _favoriteService.getFavoriteInstitutes();
      _hasLoaded = true;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      _refreshFavoritesIfRequested();
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
      const Duration(milliseconds: 200),
      () => unawaited(loadFavorites(forceRefresh: true)),
    );
  }

  void _onLocalDataChange(AppDataChange change) {
    if (change.audience != AppDataAudience.student ||
        (change.domain != AppDataDomain.courses &&
            change.domain != AppDataDomain.institutes)) {
      return;
    }

    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(loadFavorites(forceRefresh: true)),
    );
  }

  void _refreshFavoritesIfRequested() {
    if (!_refreshRequested || _isLoading || _pending.isNotEmpty) return;
    _refreshRequested = false;
    unawaited(loadFavorites(forceRefresh: true));
  }

  Future<void> toggleCourse(CourseModel course) {
    final id = course.id;
    if (id == null || !_hasLoaded) return Future.value();
    return _toggleFavorite(
      type: FavoriteTargetType.course,
      id: id,
      target: course,
      currentlyFavorite: isCourseFavorite(id),
    );
  }

  Future<void> toggleInstitute(InstituteModel institute) {
    final id = institute.id;
    if (id.isEmpty || !_hasLoaded) return Future.value();
    return _toggleFavorite(
      type: FavoriteTargetType.institute,
      id: id,
      target: institute,
      currentlyFavorite: isInstituteFavorite(id),
    );
  }

  Future<void> _toggleFavorite({
    required FavoriteTargetType type,
    required String id,
    required Object target,
    required bool currentlyFavorite,
  }) {
    final key = '${type.name}:$id';
    final pending = _pending.putIfAbsent(
      key,
      () => _PendingFavorite(
        type: type,
        id: id,
        target: target,
        persisted: currentlyFavorite,
        desired: currentlyFavorite,
      ),
    );
    pending.desired = !currentlyFavorite;
    pending.target = target;
    _setFavoriteLocally(type, id, target, pending.desired);

    final completer = Completer<void>();
    pending.waiters.add(completer);
    pending.timer?.cancel();
    pending.timer = Timer(
      const Duration(milliseconds: 350),
      () => _flushFavorite(key),
    );
    notifyListeners();
    return completer.future;
  }

  Future<void> _flushFavorite(String key) async {
    final pending = _pending[key];
    if (pending == null || pending.saving) return;
    pending.timer = null;

    if (pending.desired == pending.persisted) {
      _completePending(key, pending);
      return;
    }

    pending.saving = true;
    notifyListeners();
    final savingValue = pending.desired;

    try {
      if (savingValue) {
        await _favoriteService.addFavorite(pending.type, pending.id);
      } else {
        await _favoriteService.removeFavorite(pending.type, pending.id);
      }
      _errorMessage = null;
      pending.persisted = savingValue;
    } catch (error, stackTrace) {
      pending.desired = pending.persisted;
      _setFavoriteLocally(
        pending.type,
        pending.id,
        pending.target,
        pending.persisted,
      );
      _pending.remove(key);
      for (final waiter in pending.waiters) {
        if (!waiter.isCompleted) waiter.completeError(error, stackTrace);
      }
      notifyListeners();
      _refreshFavoritesIfRequested();
      return;
    } finally {
      pending.saving = false;
    }

    if (pending.desired == pending.persisted) {
      _completePending(key, pending);
    } else {
      pending.timer = Timer(
        const Duration(milliseconds: 350),
        () => _flushFavorite(key),
      );
      notifyListeners();
    }
  }

  void _setFavoriteLocally(
    FavoriteTargetType type,
    String id,
    Object target,
    bool isFavorite,
  ) {
    if (type == FavoriteTargetType.course) {
      _courses.removeWhere((item) => item.id == id);
      if (isFavorite && target is CourseModel) _courses.insert(0, target);
    } else {
      _institutes.removeWhere((item) => item.id == id);
      if (isFavorite && target is InstituteModel) _institutes.insert(0, target);
    }
  }

  void _completePending(String key, _PendingFavorite pending) {
    _pending.remove(key);
    for (final waiter in pending.waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
    notifyListeners();
    _refreshFavoritesIfRequested();
  }

  @override
  void dispose() {
    _realtimeRefreshTimer?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_dataChangeSubscription?.cancel());
    super.dispose();
  }
}

class _PendingFavorite {
  _PendingFavorite({
    required this.type,
    required this.id,
    required this.target,
    required this.persisted,
    required this.desired,
  });

  final FavoriteTargetType type;
  final String id;
  Object target;
  bool persisted;
  bool desired;
  bool saving = false;
  Timer? timer;
  final List<Completer<void>> waiters = [];
}
