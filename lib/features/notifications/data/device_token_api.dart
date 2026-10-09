import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';

/// Registers/unregisters this device's FCM token against the signed-in
/// user (see backend DeviceTokenController) - a push notification gets
/// addressed to a user by looking up every token registered here for
/// them. Registering the same token again (e.g. app relaunch) is a no-op
/// upsert, not a duplicate row - see the backend's own doc comment.
///
/// Actually sending a push happens server-side, in
/// NotificationService/PushNotificationSenderService, triggered by the
/// same events that raise an in-app notification (new message, lead,
/// quotation/booking status change, ...).
class DeviceTokenApi {
  final ApiClient _apiClient;

  DeviceTokenApi(this._apiClient);

  Future<void> register(String token) async {
    try {
      await _apiClient.dio.post('/api/v1/users/me/device-tokens', data: {'token': token, 'platform': 'ANDROID'});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> unregister(String token) async {
    try {
      await _apiClient.dio.delete('/api/v1/users/me/device-tokens', data: {'token': token});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
