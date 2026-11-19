import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_service.dart';
import '../../../core/state/app_data_change_bus.dart';
import '../models/institute_dashboard_model.dart';
import '../services/institute_dashboard_service.dart';

class InstituteDashboardController extends ChangeNotifier {
  InstituteDashboardController(
    this._dashboardService, {
    RealtimeService? realtimeService,
    AppDataChangeBus? dataChangeBus,
  }) {
    _realtimeSubscription = realtimeService?.events.listen(_onRealtimeEvent);
    _dataChangeSubscription = dataChangeBus?.changes.listen(
      _onLocalDataChange,
    );
  }

  static const _refreshEvents = {
    'registrationCreated',
    'registrationConfirmed',
    'registrationRejected',
    'paymentSubmitted',
    'balancePaymentSubmitted',
    'balancePaymentReviewed',
    'inPersonBalancePaymentRecorded',
    'seatAvailabilityUpdated',
    'seatHoldExpired',
    'coursePublished',
    'courseUpdated',
    'courseUnpublished',
  };

  final InstituteDashboardService _dashboardService;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  StreamSubscription<AppDataChange>? _dataChangeSubscription;
  Timer? _refreshTimer;

  InstituteDashboardData? _data;
  Object? _error;
  bool _isLoading = false;
  bool _refreshRequested = false;

  InstituteDashboardData? get data => _data;
  Object? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboard({bool forceRefresh = false}) async {
    if (_isLoading) {
      if (forceRefresh) _refreshRequested = true;
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _dashboardService.getDashboard();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
      if (_refreshRequested) {
        _refreshRequested = false;
        unawaited(fetchDashboard(forceRefresh: true));
      }
    }
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    final isReconnect = event.name == 'syncRequired';
    final isDashboardChange = _refreshEvents.contains(event.name);
    if (event.role != 'instituteOwner' ||
        (!isReconnect && !isDashboardChange)) {
      return;
    }

    _refreshTimer?.cancel();
    _refreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(fetchDashboard(forceRefresh: true)),
    );
  }

  void _onLocalDataChange(AppDataChange change) {
    if (change.audience != AppDataAudience.instituteOwner ||
        (change.domain != AppDataDomain.courses &&
            change.domain != AppDataDomain.reservations)) {
      return;
    }

    _refreshTimer?.cancel();
    _refreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(fetchDashboard(forceRefresh: true)),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_dataChangeSubscription?.cancel());
    super.dispose();
  }
}
