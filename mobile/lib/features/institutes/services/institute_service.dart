import 'dart:typed_data';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/public_data_cache.dart';
import '../models/institute_model.dart';

class InstituteService {
  InstituteService({required ApiClient apiClient, PublicApiCache? publicCache})
    : _apiClient = apiClient,
      _publicCache = publicCache;

  final ApiClient _apiClient;
  final PublicApiCache? _publicCache;

  static const _instituteListTtl = Duration(minutes: 30);

  Future<InstituteModel> getMyInstitute() async {
    final response = await _apiClient.get(
      '/api/institutes/me',
      authenticated: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('بيانات المعهد غير صالحة');
    }
    return InstituteModel.fromJson(data);
  }

  Future<InstituteModel> updateMyInstitute({
    required String name,
    required String description,
    required String phone,
    required String email,
    required String address,
  }) async {
    final response = await _apiClient.put(
      '/api/institutes/me',
      authenticated: true,
      body: {
        'name': name,
        'description': description,
        'phone': phone,
        'email': email,
        'address': address,
      },
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر حفظ بيانات المعهد');
    }
    return InstituteModel.fromJson(data);
  }

  Future<InstituteModel> uploadMyInstituteLogo({
    required Uint8List imageBytes,
    required String fileName,
    required String contentType,
  }) async {
    final response = await _apiClient.postMultipart(
      '/api/institutes/me/logo',
      authenticated: true,
      fields: const {},
      fileBytes: imageBytes,
      fileField: 'logo',
      fileName: fileName,
      contentType: contentType,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('تعذر حفظ شعار المعهد');
    }
    return InstituteModel.fromJson(data);
  }

  Future<InstitutesResponse> getInstitutes({
    String? search,
    required int page,
    required int limit,
    bool forceRefresh = false,
  }) async {
    final result = await loadInstitutes(
      search: search,
      page: page,
      limit: limit,
      forceRefresh: forceRefresh,
    );
    return result.data;
  }

  Future<InstitutesResponse?> getCachedInstitutes({
    String? search,
    required int page,
    required int limit,
  }) async {
    final cache = _publicCache;
    if (cache == null) return null;
    final queryParameters = _instituteQuery(
      search: search,
      page: page,
      limit: limit,
    );
    final key = cache.keyFor('/api/institutes', queryParameters);
    final entry = await cache.read(key);
    return entry == null ? null : _parseInstitutes(entry.data);
  }

  Future<PublicDataResult<InstitutesResponse>> loadInstitutes({
    String? search,
    required int page,
    required int limit,
    bool forceRefresh = false,
  }) async {
    final cache = _publicCache;
    final queryParameters = _instituteQuery(
      search: search,
      page: page,
      limit: limit,
    );
    if (cache == null) {
      final response = await _getInstitutesResponse(queryParameters);
      return PublicDataResult(data: _parseInstitutes(response), changed: true);
    }

    final key = cache.keyFor('/api/institutes', queryParameters);
    final result = await cache.fetchJson(
      key: key,
      ttl: _instituteListTtl,
      forceRefresh: forceRefresh,
      fetch: (etag) async {
        final response = await _getPublicInstitutesResponse(
          queryParameters,
          etag,
        );
        if (!response.notModified) {
          final data = response.data;
          if (data == null) {
            throw const FormatException('بيانات المعاهد الواردة غير صالحة');
          }
          _parseInstitutes(data);
        }
        return PublicCacheFetch(
          data: response.data,
          etag: response.etag,
          notModified: response.notModified,
        );
      },
    );
    return PublicDataResult(
      data: _parseInstitutes(result.data),
      changed: result.changed,
    );
  }

  Map<String, dynamic> _instituteQuery({
    String? search,
    required int page,
    required int limit,
  }) {
    return {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
    };
  }

  Future<Map<String, dynamic>> _getInstitutesResponse(
    Map<String, dynamic> queryParameters,
  ) async {
    try {
      return await _apiClient.get(
        '/api/institutes',
        queryParameters: queryParameters,
      );
    } on ApiException catch (error) {
      throw _translateInstituteError(error);
    }
  }

  Future<PublicGetResponse> _getPublicInstitutesResponse(
    Map<String, dynamic> queryParameters,
    String? etag,
  ) async {
    try {
      return await _apiClient.getPublic(
        '/api/institutes',
        queryParameters: queryParameters,
        ifNoneMatch: etag,
      );
    } on ApiException catch (error) {
      throw _translateInstituteError(error);
    }
  }

  ApiException _translateInstituteError(ApiException error) {
    if (error.statusCode == 404) {
      return const ApiException(
        'تعذر تحميل قائمة المعاهد حاليًا. حاول مرة أخرى لاحقًا.',
        statusCode: 404,
      );
    }
    return error;
  }

  InstitutesResponse _parseInstitutes(Map<String, dynamic> response) {
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
