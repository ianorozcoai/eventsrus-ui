import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_public_profile.dart';

class VendorDirectoryApi {
  final ApiClient _apiClient;

  VendorDirectoryApi(this._apiClient);

  /// Passing [eventId] also records/refreshes a Lead for the vendor.
  Future<VendorPublicProfile> getProfile(String slug, {int? eventId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/vendors/$slug',
        queryParameters: {if (eventId != null) 'eventId': eventId},
      );
      return VendorPublicProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
