import '../models/institute_model.dart';
import '../../../core/mock_data/institutes_data.dart';

class InstituteService {
  final List<InstituteModel> _institutes =
      List.of(institutes);

  Future<List<InstituteModel>> getInstitutes() async {
    await Future.delayed(const Duration(seconds: 1));

    return _institutes;
  }
}