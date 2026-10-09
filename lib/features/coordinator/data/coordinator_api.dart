import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/coordinator_history.dart';
import 'models/coordinator_question.dart';

/// The planner-facing "Events Coordinator" - a scoped AI ideas/advice
/// assistant for one event (see eventsrus-backend's CoordinatorController/
/// CoordinatorService). Deliberately not a general chatbot and not a
/// stand-in for vendor conversations - it never sees vendor/quotation/
/// booking data. Questions are capped per day; exceeding the cap returns
/// HTTP 429 (mapped by [mapDioError] into an [ApiException] whose message
/// is the exact "You've reached today's limit..." text from the backend).
class CoordinatorApi {
  final ApiClient _apiClient;

  CoordinatorApi(this._apiClient);

  Future<CoordinatorHistory> listHistory(int eventId) async {
    try {
      final response = await _apiClient.dio.get('/api/v1/events/$eventId/coordinator/questions');
      return CoordinatorHistory.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CoordinatorQuestion> ask(int eventId, String question) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/events/$eventId/coordinator/ask',
        data: {'question': question},
      );
      return CoordinatorQuestion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
