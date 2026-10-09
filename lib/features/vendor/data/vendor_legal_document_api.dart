import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../marketplace/data/models/vendor_legal_document.dart';
import 'models/legal_document_type.dart';

/// Business-registration documents (DTI, SEC, Mayor's Permit, Barangay
/// Clearance, BIR, ...) - a vendor can have any number, managed as their
/// own resource (VendorLegalDocumentController), separate from the big
/// Settings save. Added at onboarding too (VendorApi.becomeVendor), but
/// that's a different bulk-create path for the initial set; this is the
/// ongoing add-one/delete-one management surface.
class VendorLegalDocumentApi {
  final ApiClient _apiClient;

  VendorLegalDocumentApi(this._apiClient);

  Future<List<VendorLegalDocument>> list() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/legal-documents');
      return (response.data as List)
          .map((e) => VendorLegalDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorLegalDocument> create({
    required LegalDocumentType documentType,
    String? label,
    required PlatformFile file,
  }) async {
    final formData = FormData.fromMap({
      'documentType': documentType.toApi(),
      if (label != null && label.isNotEmpty) 'label': label,
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/legal-documents',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return VendorLegalDocument.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(int documentId) async {
    try {
      await _apiClient.dio.delete('/api/v1/vendors/me/legal-documents/$documentId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
