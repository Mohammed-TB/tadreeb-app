import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../models/admin_institute_model.dart';

class AdminInstituteService {
  AdminInstituteService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AdminInstitutePage> getInstitutes({required int page}) async {
    final response = await _apiClient.get(
      '/api/admin/institutes',
      queryParameters: {'page': page, 'limit': 50},
      authenticated: true,
    );
    return AdminInstitutePage.fromJson(response);
  }

  Future<void> createInstitute({
    required String instituteName,
    required String institutePhone,
    required String instituteAddress,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    String? instituteDescription,
    String? instituteEmail,
    String? ownerPhone,
    Uint8List? logoBytes,
    String? logoName,
    String? logoContentType,
  }) async {
    final institute = <String, dynamic>{
      'name': instituteName.trim(),
      'phone': institutePhone.trim(),
      'address': instituteAddress.trim(),
      'description': ?_nonEmpty(instituteDescription),
      'email': ?_nonEmpty(instituteEmail),
    };
    final owner = <String, dynamic>{
      'name': ownerName.trim(),
      'email': ownerEmail.trim().toLowerCase(),
      'phone': ?_nonEmpty(ownerPhone),
      'password': ownerPassword,
    };

    if (logoBytes != null) {
      if (logoName == null || logoContentType == null) {
        throw ArgumentError(
          'Logo name and content type are required when uploading a logo',
        );
      }

      await _apiClient.postMultipart(
        '/api/admin/institutes/with-logo',
        authenticated: true,
        fields: {
          'institute': jsonEncode(institute),
          'owner': jsonEncode(owner),
        },
        fileBytes: logoBytes,
        fileField: 'logo',
        fileName: logoName,
        contentType: logoContentType,
      );
      return;
    }

    await _apiClient.post(
      '/api/admin/institutes',
      authenticated: true,
      body: {'institute': institute, 'owner': owner},
    );
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
