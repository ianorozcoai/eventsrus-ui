import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../auth/data/models/auth_response.dart';
import 'models/legal_document_type.dart';
import 'models/legal_document_upload.dart';
import 'models/vendor_onboarding_request.dart';

class VendorApi {
  final ApiClient _apiClient;

  VendorApi(this._apiClient);

  Future<AuthResponse> becomeVendor({
    required VendorOnboardingRequest request,
    PlatformFile? logo,
    PlatformFile? idCard,
    PlatformFile? selfie,
    List<LegalDocumentUpload> legalDocuments = const [],
  }) async {
    final formData = FormData.fromMap({
      ...request.toFormFields(),
      if (logo != null) 'logo': MultipartFile.fromBytes(logo.bytes!, filename: logo.name),
      if (idCard != null) 'idCard': MultipartFile.fromBytes(idCard.bytes!, filename: idCard.name),
      if (selfie != null) 'selfie': MultipartFile.fromBytes(selfie.bytes!, filename: selfie.name),
      // Parallel lists correlated by index - a vendor can attach any number
      // of business-registration documents now (DTI, SEC, Mayor's Permit,
      // Barangay Clearance, BIR, ...), not just one "business permit".
      if (legalDocuments.isNotEmpty) ...{
        'legalDocumentFiles': legalDocuments
            .map((doc) => MultipartFile.fromBytes(doc.file.bytes!, filename: doc.file.name))
            .toList(),
        'legalDocumentTypes': legalDocuments.map((doc) => doc.type.toApi()).toList(),
        'legalDocumentLabels': legalDocuments.map((doc) => doc.label ?? '').toList(),
      },
    });

    try {
      final response = await _apiClient.dio.patch(
        '/api/v1/users/me/vendor',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
