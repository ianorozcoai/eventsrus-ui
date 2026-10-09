import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/social_media_platform.dart';
import 'models/vendor_social_media_link.dart';

class VendorSocialMediaApi {
  final ApiClient _apiClient;

  VendorSocialMediaApi(this._apiClient);

  Future<List<VendorSocialMediaLink>> list() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/social-media-links');
      return (response.data as List)
          .map((json) => VendorSocialMediaLink.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VendorSocialMediaLink> addLink(SocialMediaPlatform platform, String url) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/social-media-links',
        data: {'platform': platform.toApi(), 'url': url},
      );
      return VendorSocialMediaLink.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deleteLink(int linkId) async {
    try {
      await _apiClient.dio.delete('/api/v1/vendors/me/social-media-links/$linkId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
