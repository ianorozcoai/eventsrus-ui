import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'moderation_models.dart';

/// Report and block (Google Play requires both wherever users can message
/// each other). A report is only a note to the admin - nothing is hidden or
/// removed by it. A block stops the two people messaging each other; old
/// messages stay visible. See eventsrus-backend's ModerationService.
class ModerationApi {
  final ApiClient _apiClient;

  ModerationApi(this._apiClient);

  Future<void> report({
    required ReportContentType contentType,
    required int contentId,
    required ReportReason reason,
    String? details,
  }) async {
    try {
      await _apiClient.dio.post('/api/v1/reports', data: {
        'contentType': contentType.toApi(),
        'contentId': contentId,
        'reason': reason.toApi(),
        if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
      });
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> blockUser(int userId) async {
    try {
      await _apiClient.dio.post('/api/v1/users/$userId/block');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> unblockUser(int userId) async {
    try {
      await _apiClient.dio.delete('/api/v1/users/$userId/block');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<BlockedUser>> listBlocked() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/users/me/blocks');
      return (response.data as List<dynamic>)
          .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
