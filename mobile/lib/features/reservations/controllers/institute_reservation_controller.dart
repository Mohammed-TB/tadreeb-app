import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/realtime/realtime_service.dart';
import '../../../core/state/app_data_change_bus.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';

class InstituteReservationController extends ChangeNotifier {
  InstituteReservationController(
    this._reservationService, {
    RealtimeService? realtimeService,
    AppDataChangeBus? dataChangeBus,
  }) {
    _realtimeSubscription = realtimeService?.events.listen(_onRealtimeEvent);
    _dataChangeSubscription = dataChangeBus?.changes.listen(_onLocalDataChange);
    _dataChangeBus = dataChangeBus;
  }

  final ReservationService _reservationService;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  StreamSubscription<AppDataChange>? _dataChangeSubscription;
  Timer? _realtimeRefreshTimer;
  late final AppDataChangeBus? _dataChangeBus;

  List<ReservationModel> _reservations = [];
  List<ReservationModel> get reservations => _reservations;

  // الفلترة والبحث
  String _searchQuery = '';
  String? _statusFilter;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;

  // الحالات العامة
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _refreshRequested = false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // معالجة الأزرار بشكل منفرد لمنع التكرار
  final Set<String> _processingIds = {};
  bool isProcessing(String reservationId) =>
      _processingIds.contains(reservationId);

  /// الحجوزات المفلترة
  List<ReservationModel> get filteredReservations {
    return _reservations.where((r) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.studentPhone.contains(_searchQuery) ||
          (r.courseTitle != null &&
              r.courseTitle!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ));

      final matchesStatus =
          _statusFilter == null ||
          _statusFilter == 'ALL' ||
          _normalizeStatus(r.status) == _normalizeStatus(_statusFilter!);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  /// توحيد مقارنة الحالات (يدعم camelCase و snake_case)
  static String _normalizeStatus(String status) {
    return status.replaceAll('_', '').toLowerCase();
  }

  /// إحصائيات سريعة للوحة
  int get totalCount => _reservations.length;

  int get pendingCount => _reservations.where((r) {
    final s = _normalizeStatus(r.status);
    return s == 'paymentsubmitted';
  }).length;

  int get confirmedCount => _reservations
      .where((r) => _normalizeStatus(r.status) == 'confirmed')
      .length;

  int get rejectedCount => _reservations
      .where((r) => _normalizeStatus(r.status) == 'rejected')
      .length;

  /// جلب الحجوزات من الـ Backend
  Future<void> fetchReservations({bool forceRefresh = false}) async {
    if (_isLoading) {
      if (forceRefresh) _refreshRequested = true;
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reservations = await _reservationService.getMyReservations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      if (_refreshRequested) {
        _refreshRequested = false;
        unawaited(fetchReservations(forceRefresh: true));
      }
    }
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    final isInstituteReconnect =
        event.name == 'syncRequired' && event.role == 'instituteOwner';
    final isRegistrationChange = {
      'registrationCreated',
      'registrationConfirmed',
      'registrationRejected',
      'paymentSubmitted',
      'balancePaymentSubmitted',
      'inPersonBalancePaymentRecorded',
      'seatHoldExpired',
    }.contains(event.name);
    if ((!isInstituteReconnect && !isRegistrationChange) ||
        (isRegistrationChange && event.role != 'instituteOwner')) {
      return;
    }

    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(fetchReservations(forceRefresh: true)),
    );
  }

  void _onLocalDataChange(AppDataChange change) {
    if (change.audience != AppDataAudience.instituteOwner ||
        change.domain != AppDataDomain.reservations ||
        change.origin == AppDataChangeOrigin.instituteReservations) {
      return;
    }

    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(fetchReservations(forceRefresh: true)),
    );
  }

  /// تغيير معيار البحث
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// تغيير فلتر الحالة
  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  /// قبول وموافقة على الحجز (PATCH /api/institutes/me/reservations/:id/approve)
  Future<bool> approveReservation(String reservationId) async {
    if (_processingIds.contains(reservationId)) return false;

    _processingIds.add(reservationId);
    notifyListeners();

    try {
      final updated = await _reservationService.approveReservation(
        reservationId,
      );
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] = updated;
      } else {
        await fetchReservations();
      }
      _dataChangeBus?.notifyChanged(
        AppDataDomain.reservations,
        AppDataChangeOrigin.instituteReservations,
        audience: AppDataAudience.instituteOwner,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _processingIds.remove(reservationId);
      notifyListeners();
    }
  }

  /// رفض الحجز مع سبب إلزامي (PATCH /api/institutes/me/reservations/:id/reject)
  Future<bool> rejectReservation(
    String reservationId, {
    required String reason,
  }) async {
    if (_processingIds.contains(reservationId)) return false;

    _processingIds.add(reservationId);
    notifyListeners();

    try {
      final updated = await _reservationService.rejectReservation(
        reservationId,
        reason: reason,
      );
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] = updated;
      } else {
        await fetchReservations();
      }
      _dataChangeBus?.notifyChanged(
        AppDataDomain.reservations,
        AppDataChangeOrigin.instituteReservations,
        audience: AppDataAudience.instituteOwner,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _processingIds.remove(reservationId);
      notifyListeners();
    }
  }

  /// جلب رابط السند / الإيصال (GET /api/institutes/me/reservations/:id/receipt)
  Future<String?> getReceiptUrl(String reservationId) async {
    try {
      return await _reservationService.getReceiptUrl(reservationId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<String?> getBalancePaymentReceiptUrl(String reservationId) async {
    try {
      return await _reservationService.getBalancePaymentReceiptUrl(
        reservationId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> _reviewBalancePayment(
    String reservationId,
    Future<ReservationModel> Function() review,
  ) async {
    if (_processingIds.contains(reservationId)) return false;
    _processingIds.add(reservationId);
    notifyListeners();

    try {
      final updated = await review();
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] = updated;
      } else {
        await fetchReservations();
      }
      _dataChangeBus?.notifyChanged(
        AppDataDomain.reservations,
        AppDataChangeOrigin.instituteReservations,
        audience: AppDataAudience.instituteOwner,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _processingIds.remove(reservationId);
      notifyListeners();
    }
  }

  Future<bool> approveBalancePayment(String reservationId) =>
      _reviewBalancePayment(
        reservationId,
        () => _reservationService.approveBalancePayment(reservationId),
      );

  Future<bool> rejectBalancePayment(
    String reservationId, {
    required String reason,
  }) => _reviewBalancePayment(
    reservationId,
    () =>
        _reservationService.rejectBalancePayment(reservationId, reason: reason),
  );

  Future<bool> recordInPersonBalancePayment(String reservationId) =>
      _reviewBalancePayment(
        reservationId,
        () => _reservationService.recordInPersonBalancePayment(reservationId),
      );

  Future<bool> createInPersonReservation({
    required String courseId,
    required String studentName,
    required String studentPhone,
    required String paymentOption,
  }) async {
    const operationId = 'in-person-registration';
    if (_processingIds.contains(operationId)) return false;

    _processingIds.add(operationId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _reservationService.createInPersonReservation(
        courseId: courseId,
        studentName: studentName,
        studentPhone: studentPhone,
        paymentOption: paymentOption,
      );
      await fetchReservations();
      _dataChangeBus?.notifyChanged(
        AppDataDomain.reservations,
        AppDataChangeOrigin.instituteReservations,
        audience: AppDataAudience.instituteOwner,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _processingIds.remove(operationId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _realtimeRefreshTimer?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_dataChangeSubscription?.cancel());
    super.dispose();
  }
}
