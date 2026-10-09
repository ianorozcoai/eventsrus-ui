import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/vendor_dashboard.dart';

class VendorDashboardApi {
  final ApiClient _apiClient;

  VendorDashboardApi(this._apiClient);

  Future<VendorDashboard> getDashboard() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/dashboard');
      return VendorDashboard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
