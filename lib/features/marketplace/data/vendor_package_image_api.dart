import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_package_image.dart';

/// Real per-package photos - see backend VendorPackageImageController's own
/// doc comment (combined across every package these also make up the
/// storefront's Gallery, but that combined view is a separate mobile
/// feature out of scope here).
class VendorPackageImageApi {
  final ApiClient _apiClient;

  VendorPackageImageApi(this._apiClient);

  Future<List<VendorPackageImage>> list(int packageId) async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/packages/$packageId/images');
      return (response.data as List)
          .map((e) => VendorPackageImage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorPackageImage> upload(int packageId, PlatformFile image, {String? caption}) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(image.bytes!, filename: image.name),
      if (caption != null) 'caption': caption,
    });

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/packages/$packageId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return VendorPackageImage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(int packageId, int imageId) async {
    try {
      await _apiClient.dio.delete('/api/v1/vendors/me/packages/$packageId/images/$imageId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Replaces this photo's full tag set (not additive) - matches backend
  /// VendorPackageImageController's PUT .../{imageId}/tags. Package photos
  /// are tag-editable from the Gallery screen's "All Images" section, same
  /// as this method's VendorGalleryApi.setTags counterpart for standalone
  /// photos, even though upload/delete for a package photo stays on the
  /// Packages screen.
  Future<void> setTags(int packageId, int imageId, List<int> tagIds) async {
    try {
      await _apiClient.dio.put('/api/v1/vendors/me/packages/$packageId/images/$imageId/tags', data: tagIds);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
