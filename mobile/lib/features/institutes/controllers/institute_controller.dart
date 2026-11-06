import 'package:flutter/foundation.dart';
import '../models/institute_model.dart';
import '../services/institute_service.dart';

class InstituteController extends ChangeNotifier {
  final InstituteService _instituteService;

  InstituteController(this._instituteService);

  List<InstituteModel> _institutes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<InstituteModel> get institutes => _institutes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> getInstitutes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _institutes = await _instituteService.getInstitutes();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}