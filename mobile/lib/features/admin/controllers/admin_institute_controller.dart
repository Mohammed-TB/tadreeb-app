import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../models/admin_institute_model.dart';
import '../services/admin_institute_service.dart';

class AdminInstituteController extends ChangeNotifier {
  AdminInstituteController(this._service);

  final AdminInstituteService _service;

  List<AdminInstituteModel> _institutes = [];
  List<AdminInstituteModel> get institutes => List.unmodifiable(_institutes);

  List<AdminInstituteModel> get visibleInstitutes {
    final selectedStatus = _selectedStatus;
    if (selectedStatus == null) return institutes;
    return List.unmodifiable(
      _institutes.where((institute) => institute.status == selectedStatus),
    );
  }

  AdminInstituteStatus? _selectedStatus;
  AdminInstituteStatus? get selectedStatus => _selectedStatus;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _refreshAfterLoad = false;

  bool _hasLoaded = false;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _total = 0;
  int get total => _total;

  Future<void> loadInstitutes({bool forceRefresh = false}) async {
    if (_isLoading) {
      if (forceRefresh) _refreshAfterLoad = true;
      return;
    }
    if (_hasLoaded && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allInstitutes = <AdminInstituteModel>[];
      var result = await _service.getInstitutes(page: 1);
      allInstitutes.addAll(result.institutes);

      for (var page = 2; page <= result.totalPages; page++) {
        result = await _service.getInstitutes(page: page);
        allInstitutes.addAll(result.institutes);
      }

      _institutes = allInstitutes;
      _total = result.total;
      _hasLoaded = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } on FormatException {
      _errorMessage = 'استجابة قائمة المعاهد من الخادم غير صالحة';
    } finally {
      _isLoading = false;
      notifyListeners();
      if (_refreshAfterLoad) {
        _refreshAfterLoad = false;
        await loadInstitutes(forceRefresh: true);
      }
    }
  }

  void selectStatus(AdminInstituteStatus? status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
  }
}
