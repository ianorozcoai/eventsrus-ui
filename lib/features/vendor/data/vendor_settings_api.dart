import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_settings.dart';

class VendorSettingsApi {
  final ApiClient _apiClient;

  VendorSettingsApi(this._apiClient);

  Future<VendorSettings> getSettings() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/settings');
      return VendorSettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  // VendorSettingsController#updateSettings is multipart/form-data only - a
  // plain JSON body would get rejected with a 415, since `@ModelAttribute
  // VendorSettingsRequest` only binds from form fields, not a request body.
  // The 5 file parts are each optional - omitted entirely unless the vendor
  // picked a replacement this save, same as web leaving that <input
  // type="file"> empty.
  Future<VendorSettings> updateSettings(
    VendorSettings settings, {
    PlatformFile? logo,
    PlatformFile? idCard,
    PlatformFile? selfie,
    PlatformFile? cancellationPolicyFile,
    PlatformFile? refundTermsFile,
  }) async {
    final fields = <String, dynamic>{};
    settings.toJson().forEach((key, value) {
      if (value == null) return;
      fields[key] = value;
    });

    final formData = FormData.fromMap({
      ...fields,
      if (logo != null) 'logo': MultipartFile.fromBytes(logo.bytes!, filename: logo.name),
      if (idCard != null) 'idCard': MultipartFile.fromBytes(idCard.bytes!, filename: idCard.name),
      if (selfie != null) 'selfie': MultipartFile.fromBytes(selfie.bytes!, filename: selfie.name),
      if (cancellationPolicyFile != null)
        'cancellationPolicyFile':
            MultipartFile.fromBytes(cancellationPolicyFile.bytes!, filename: cancellationPolicyFile.name),
      if (refundTermsFile != null)
        'refundTermsFile': MultipartFile.fromBytes(refundTermsFile.bytes!, filename: refundTermsFile.name),
    });

    try {
      final response = await _apiClient.dio.put(
        '/api/v1/vendors/me/settings',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return VendorSettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
