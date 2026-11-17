import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/realtime/realtime_service.dart';
import '../../../core/state/app_data_change_bus.dart';
import '../../students/models/student_reservation_model.dart';
import '../services/reservation_service.dart';

class ReservationController extends ChangeNotifier {
  ReservationController(
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

  // الحجز الجديد
  String? _reservationId;
  String? get reservationId => _reservationId;

  // قائمة حجوزات الطالب
  List<StudentReservationModel> _myReservations = [];
  List<StudentReservationModel> get myReservations => _myReservations;

  // فلتر الحالات والبحث
  String _searchQuery = '';
  String? _statusFilter;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;

  // حالات التحميل والخطأ
  bool _isLoadingReservations = false;
  bool get isLoadingReservations => _isLoadingReservations;
  bool _refreshRequested = false;

  bool _isCreatingReservation = false;
  bool get isCreatingReservation => _isCreatingReservation;

  bool _isUploadingReceipt = false;
  bool get isUploadingReceipt => _isUploadingReceipt;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // معرف الحجز الجاري رفع سند له حالياً
  String? _uploadingReservationId;
  bool isUploadingFor(String id) =>
      _isUploadingReceipt && _uploadingReservationId == id;

  void _onLocalDataChange(AppDataChange change) {
    if (change.audience != AppDataAudience.student ||
        change.domain != AppDataDomain.reservations ||
        change.origin == AppDataChangeOrigin.studentReservations) {
      return;
    }

    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(fetchMyReservations(forceRefresh: true)),
    );
  }

  /// الحجوزات بعد تطبيق شروط البحث والفلترة
  List<StudentReservationModel> get filteredReservations {
    return _myReservations.where((r) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          r.courseTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.instituteName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _statusFilter == null ||
          _statusFilter == 'ALL' ||
          _normalizeStatus(r.status) == _normalizeStatus(_statusFilter!);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  static String _normalizeStatus(String status) {
    return status.replaceAll('_', '').toLowerCase();
  }

  /// إحصائيات سريعة لحجوزات الطالب
  int get totalCount => _myReservations.length;

  int get pendingPaymentCount => _myReservations.where((r) {
    final s = _normalizeStatus(r.status);
    return s == 'pendingpayment';
  }).length;

  int get underReviewCount => _myReservations.where((r) {
    final s = _normalizeStatus(r.status);
    return s == 'paymentsubmitted';
  }).length;

  int get confirmedCount => _myReservations
      .where((r) => _normalizeStatus(r.status) == 'confirmed')
      .length;

  int get rejectedCount => _myReservations
      .where((r) => _normalizeStatus(r.status) == 'rejected')
      .length;

  /// جلب حجوزات الطالب من الخادم: GET /api/reservations/my
  Future<void> fetchMyReservations({bool forceRefresh = false}) async {
    if (_isLoadingReservations) {
      if (forceRefresh) _refreshRequested = true;
      return;
    }

    _isLoadingReservations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myReservations = await _reservationService.getMyReservations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingReservations = false;
      notifyListeners();
      if (_refreshRequested) {
        _refreshRequested = false;
        unawaited(fetchMyReservations(forceRefresh: true));
      }
    }
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    final isStudentReconnect =
        event.name == 'syncRequired' && event.role == 'student';
    final isStatusChange = {
      'registrationConfirmed',
      'registrationRejected',
      'seatHoldExpired',
      'balancePaymentReviewed',
    }.contains(event.name);
    if ((!isStudentReconnect && !isStatusChange) ||
        (isStatusChange && event.role != 'student')) {
      return;
    }

    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(fetchMyReservations(forceRefresh: true)),
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  // إنشاء حجز إلكتروني جديد
  Future<bool> createOnlineReservation({
    required String courseId,
    required String studentName,
    required String studentPhone,
    required String paymentOption,
  }) async {
    if (_isCreatingReservation) return false;

    _isCreatingReservation = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      debugPrint('========== CREATE REGISTRATION START ==========');
      debugPrint('Course ID: $courseId');
      final id = await _reservationService.createOnlineReservation(
        courseId: courseId,
        studentName: studentName,
        studentPhone: studentPhone,
        paymentOption: paymentOption,
      );
      debugPrint('========== CREATE REGISTRATION SUCCESS ==========');
      _reservationId = id;
      _successMessage = 'تم إنشاء الحجز بنجاح';
      _dataChangeBus?.notifyChanged(
        AppDataDomain.reservations,
        AppDataChangeOrigin.studentReservations,
        audience: AppDataAudience.student,
      );
      await fetchMyReservations(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isCreatingReservation = false;
      notifyListeners();
    }
  }

  // رفع سند الدفع للحجز
  Future<bool> uploadReceipt({
    required String reservationId,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    if (_isUploadingReceipt) return false;

    _isUploadingReceipt = true;
    _uploadingReservationId = reservationId;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _reservationService.uploadReceipt(
        reservationId: reservationId,
        fileBytes: fileBytes,
        fileName: fileName,
        contentType: contentType,
      );

      _successMessage = 'تم رفع سند الدفع بنجاح وهو قيد مراجعة المعهد';
      _dataChangeBus?.notifyChanged(
        AppDataDomain.reservations,
        AppDataChangeOrigin.studentReservations,
        audience: AppDataAudience.student,
      );
      // تحديث القائمة بعد الرفع لتنعكس الحالة فوراً
      await fetchMyReservations();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isUploadingReceipt = false;
      _uploadingReservationId = null;
      notifyListeners();
    }
  }

  Future<bool> uploadBalancePaymentReceipt({
    required String reservationId,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    if (_isUploadingReceipt) return false;

    _isUploadingReceipt = true;
    _uploadingReservationId = reservationId;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _reservationService.uploadBalancePaymentReceipt(
        reservationId: reservationId,
        fileBytes: fileBytes,
        fileName: fileName,
        contentType: contentType,
      );
      _successMessage = 'تم رفع سند الدفعة المتبقية وهو قيد مراجعة المعهد';
      _dataChangeBus?.notifyChanged(
        AppDataDomain.reservations,
        AppDataChangeOrigin.studentReservations,
        audience: AppDataAudience.student,
      );
      await fetchMyReservations(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isUploadingReceipt = false;
      _uploadingReservationId = null;
      notifyListeners();
    }
  }

  // رابط صورة السند
  Future<String?> getReceiptUrl(String reservationId) async {
    try {
      return await _reservationService.getReceiptUrl(reservationId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }

  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void resetReservation() {
    _reservationId = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeRefreshTimer?.cancel();
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_dataChangeSubscription?.cancel());
    super.dispose();
  }
}
