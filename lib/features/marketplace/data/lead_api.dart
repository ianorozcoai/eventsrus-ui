import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/lead.dart';

class LeadApi {
  final ApiClient _apiClient;

  LeadApi(this._apiClient);

  Future<List<Lead>> listForVendor() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/leads');
      return (response.data as List).map((e) => Lead.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
