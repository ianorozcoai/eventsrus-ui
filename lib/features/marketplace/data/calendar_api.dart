import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/calendar_entry.dart';

class CalendarApi {
  final ApiClient _apiClient;

  CalendarApi(this._apiClient);

  Future<List<CalendarEntry>> plannerCalendar() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/planners/me/calendar');
      return (response.data as List).map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<CalendarEntry>> vendorCalendar() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/calendar');
      return (response.data as List).map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
