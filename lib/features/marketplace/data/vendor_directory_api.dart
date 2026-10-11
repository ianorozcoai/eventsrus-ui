import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_public_profile.dart';
import 'models/vendor_search_result.dart';

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

  /// Deliberate name search for a specific vendor the planner already has
  /// in mind - distinct from an event's AI-generated suggestions, which
  /// only ever surface whoever the matching algorithm picked.
  Future<List<VendorSearchResult>> search(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/vendors/search',
        queryParameters: {'query': query},
      );
      return (response.data as List)
          .map((e) => VendorSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
