import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/gallery_photo_limit.dart';
import 'models/vendor_gallery_photo.dart';

/// Standalone storefront photos, not attached to any package - see backend
/// VendorGalleryPhotoController's own doc comment. Distinct from
/// VendorPackageImageApi (per-package photos); the combined "every image a
/// vendor has" view (VendorImageTagController's `/images` endpoint) is a
/// separate, not-yet-built mobile feature - see VendorPackageImageApi's own
/// doc comment.
class VendorGalleryApi {
  final ApiClient _apiClient;

  VendorGalleryApi(this._apiClient);

  Future<List<VendorGalleryPhoto>> list() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/gallery');
      return (response.data as List)
          .map((e) => VendorGalleryPhoto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<GalleryPhotoLimit> limit() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/gallery/limit');
      return GalleryPhotoLimit.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorGalleryPhoto> upload(PlatformFile image, {String? caption}) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(image.bytes!, filename: image.name),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/gallery',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return VendorGalleryPhoto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(int photoId) async {
    try {
      await _apiClient.dio.delete('/api/v1/vendors/me/gallery/$photoId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Replaces this photo's full tag set (not additive) - matches backend
  /// VendorImageTagService#setGalleryPhotoTags.
  Future<void> setTags(int photoId, List<int> tagIds) async {
    try {
      await _apiClient.dio.put('/api/v1/vendors/me/gallery/$photoId/tags', data: tagIds);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
