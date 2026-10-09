import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/notification_item.dart';

class NotificationApi {
  final ApiClient _apiClient;

  NotificationApi(this._apiClient);

  Future<List<NotificationItem>> list() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/notifications');
      return (response.data as List).map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/notifications/unread-count');
      return (response.data as Map<String, dynamic>)['count'] as int;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markRead(int notificationId) async {
    try {
      await _apiClient.dio.put('/api/v1/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
