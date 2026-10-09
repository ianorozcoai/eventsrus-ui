import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_referral_overview.dart';

class VendorReferralApi {
  final ApiClient _apiClient;

  VendorReferralApi(this._apiClient);

  Future<VendorReferralOverview> getOverview() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/referrals');
      return VendorReferralOverview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
