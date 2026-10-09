import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/conversation_message.dart';
import 'models/conversation_summary.dart';

class ConversationApi {
  final ApiClient _apiClient;

  ConversationApi(this._apiClient);

  Future<ConversationMessage> sendInquiry({
    required int eventId,
    required int vendorUserId,
    required String plannerName,
    DateTime? targetDate,
    required String message,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/events/$eventId/vendors/$vendorUserId/inquiries',
        data: {
          'plannerName': plannerName,
          if (targetDate != null) 'targetDate': _dateOnly(targetDate),
          'message': message,
        },
      );
      return ConversationMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// A vendor reaching out first to a lead (a planner who viewed their
  /// storefront but hasn't messaged yet) - creates a new conversation for
  /// this event. See ConversationService#sendVendorMessage.
  Future<ConversationMessage> sendVendorMessage(int eventId, String message) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/events/$eventId/vendor-messages',
        data: {'message': message},
      );
      return ConversationMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<ConversationSummary>> listConversations() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/conversations');
      return (response.data as List)
          .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<ConversationMessage>> getMessages(int conversationId) async {
    try {
      final response = await _apiClient.dio.get('/api/v1/conversations/$conversationId/messages');
      return (response.data as List)
          .map((e) => ConversationMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ConversationMessage> sendMessage(
    int conversationId,
    String message, {
    Uint8List? attachmentBytes,
    String? attachmentFilename,
  }) async {
    try {
      final data = attachmentBytes == null
          ? {'message': message}
          : FormData.fromMap({
              'message': message,
              'attachment': MultipartFile.fromBytes(attachmentBytes, filename: attachmentFilename),
            });
      final response = await _apiClient.dio.post(
        '/api/v1/conversations/$conversationId/messages',
        data: data,
        options: attachmentBytes == null ? null : Options(contentType: 'multipart/form-data'),
      );
      return ConversationMessage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
