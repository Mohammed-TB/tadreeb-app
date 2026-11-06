import 'package:project_1/features/institutes/models/institute_model.dart';

class InstituteService {

  List<InstituteModel> _institutes = institutes;

Future<List<InstituteModel>> getInstitutes() async {
    await Future.delayed(const Duration(seconds: 1));
    return _institutes;
  }
}