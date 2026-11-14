import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';

class InstituteReservationController extends ChangeNotifier {
  InstituteReservationController(this._reservationService);

  final ReservationService _reservationService;

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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // معالجة الأزرار بشكل منفرد لمنع التكرار
  final Set<String> _processingIds = {};
  bool isProcessing(String reservationId) => _processingIds.contains(reservationId);

  /// الحجوزات المفلترة
  List<ReservationModel> get filteredReservations {
    return _reservations.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.studentPhone.contains(_searchQuery) ||
          (r.courseTitle != null &&
              r.courseTitle!.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesStatus = _statusFilter == null ||
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
  Future<void> fetchReservations() async {
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
    }
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
      final updated = await _reservationService.approveReservation(reservationId);
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] = updated;
      } else {
        await fetchReservations();
      }
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
  Future<bool> rejectReservation(String reservationId, {required String reason}) async {
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
}
