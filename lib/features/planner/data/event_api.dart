import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/planner_event.dart';
import 'models/planner_event_type.dart';

class EventApi {
  final ApiClient _apiClient;

  EventApi(this._apiClient);

  Future<PlannerEvent> createEvent({
    required PlannerEventType eventType,
    DateTime? eventDate,
    String? location,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/events',
        data: {
          'eventType': eventType.toApi(),
          if (eventDate != null) 'eventDate': _dateOnly(eventDate),
          'location': location,
          'description': description,
        },
      );
      return PlannerEvent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<PlannerEventSummary>> listEvents() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/events');
      return (response.data as List).map((e) => PlannerEventSummary.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PlannerEvent> getEvent(int eventId) async {
    try {
      final response = await _apiClient.dio.get('/api/v1/events/$eventId');
      return PlannerEvent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PlannerEvent> saveEvent(int eventId, String name) async {
    try {
      final response = await _apiClient.dio.put('/api/v1/events/$eventId/save', data: {'name': name});
      return PlannerEvent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<EventChecklistItem> addChecklistItem(int eventId, String label) async {
    try {
      final response = await _apiClient.dio.post('/api/v1/events/$eventId/checklist', data: {'label': label});
      return EventChecklistItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<EventChecklistItem> updateChecklistStatus(int eventId, int itemId, ChecklistItemStatus status) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/events/$eventId/checklist/$itemId',
        data: {'status': status == ChecklistItemStatus.done ? 'DONE' : 'TODO'},
      );
      return EventChecklistItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
