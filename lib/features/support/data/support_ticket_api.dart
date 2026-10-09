import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/support_ticket.dart';
import 'models/support_ticket_message.dart';
import 'models/ticket_category.dart';

class SupportTicketApi {
  final ApiClient _apiClient;

  SupportTicketApi(this._apiClient);

  Future<List<SupportTicket>> listForUser() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/support-tickets/me');
      return (response.data as List).map((json) => SupportTicket.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SupportTicket> getTicket(int ticketId) async {
    try {
      final response = await _apiClient.dio.get('/api/v1/support-tickets/$ticketId');
      return SupportTicket.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<SupportTicketMessage>> getMessages(int ticketId) async {
    try {
      final response = await _apiClient.dio.get('/api/v1/support-tickets/$ticketId/messages');
      return (response.data as List)
          .map((json) => SupportTicketMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// [attachment] (a screenshot of the issue, say) is optional - the
  /// opening message is required and becomes the ticket's first
  /// SupportTicketMessage. relatedEventId/relatedBookingId/relatedQuotationId
  /// are left out for now (optional on the backend too) - linking a ticket
  /// to a specific booking/quotation from the UI is a fast-follow, not
  /// needed for a vendor/planner to raise a general issue today.
  Future<SupportTicket> createTicket({
    required String subject,
    required TicketCategory category,
    required String message,
    PlatformFile? attachment,
  }) async {
    final formData = FormData.fromMap({
      'subject': subject,
      'category': category.toApi(),
      'message': message,
      if (attachment != null) 'attachment': MultipartFile.fromBytes(attachment.bytes!, filename: attachment.name),
    });

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/support-tickets',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return SupportTicket.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SupportTicket> reply(int ticketId, String message, {PlatformFile? attachment}) async {
    final formData = FormData.fromMap({
      'message': message,
      if (attachment != null) 'attachment': MultipartFile.fromBytes(attachment.bytes!, filename: attachment.name),
    });

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/support-tickets/$ticketId/messages',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return SupportTicket.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
