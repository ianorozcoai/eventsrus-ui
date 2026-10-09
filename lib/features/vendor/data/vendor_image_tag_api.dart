import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_image_tag.dart';
import 'models/vendor_tagged_image.dart';

/// Vendor-created tags shared across package photos and standalone gallery
/// photos - see backend VendorImageTagController/VendorImageTagService.
class VendorImageTagApi {
  final ApiClient _apiClient;

  VendorImageTagApi(this._apiClient);

  Future<List<VendorImageTag>> list() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/image-tags');
      return (response.data as List)
          .map((e) => VendorImageTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Every image the vendor has - standalone gallery photos and every
  /// package's own photos, combined (see
  /// VendorImageTagService#listAllTaggableImages). This is what backs the
  /// Gallery screen's "All Images" section - the same combined set the
  /// storefront's own Gallery shows, which is why a vendor could otherwise
  /// see more photos there than in just the standalone-only section below.
  Future<List<VendorTaggedImage>> images() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/image-tags/images');
      return (response.data as List)
          .map((e) => VendorTaggedImage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorImageTag> create(String name) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/image-tags',
        data: {'name': name},
      );
      return VendorImageTag.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(int tagId) async {
    try {
      await _apiClient.dio.delete('/api/v1/vendors/me/image-tags/$tagId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
