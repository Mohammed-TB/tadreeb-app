import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/institute_model.dart';

class InstituteService {
  InstituteService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<InstitutesResponse> getInstitutes({
    String? search,
    required int page,
    required int limit,
  }) async {
    final Map<String, dynamic> response;
    try {
      response = await _apiClient.get(
        '/api/institutes',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        throw const ApiException(
          'مسار المعاهد غير منشور على الخادم الحالي. انشر تحديث الـ Backend ثم أعد المحاولة.',
          statusCode: 404,
        );
      }
      rethrow;
    }

    final data = response['data'];
    final pagination = response['pagination'];
    if (data is! List || pagination is! Map<String, dynamic>) {
      throw const FormatException('بيانات المعاهد الواردة من الخادم غير صالحة');
    }

    return InstitutesResponse(
      institutes: data.map((institute) {
        if (institute is! Map<String, dynamic>) {
          throw const FormatException('بيانات أحد المعاهد غير صالحة');
        }
        return InstituteModel.fromJson(institute);
      }).toList(),
      page: _readInt(pagination['page']),
      totalPages: _readInt(pagination['totalPages']),
      total: _readInt(pagination['total']),
    );
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('بيانات ترقيم صفحات المعاهد غير صالحة');
  }
}

class InstitutesResponse {
  const InstitutesResponse({
    required this.institutes,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<InstituteModel> institutes;
  final int page;
  final int totalPages;
  final int total;
}
