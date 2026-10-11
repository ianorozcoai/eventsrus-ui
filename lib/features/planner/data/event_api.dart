import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/event_recommendations.dart';
import 'models/planner_event.dart';
import 'models/planner_event_type.dart';

class EventApi {
  final ApiClient _apiClient;

  EventApi(this._apiClient);

  /// Essential/optional supplier categories for an event type, with no
  /// event created yet - lets the create-event wizard's step 2 render its
  /// category checklist before anything is saved (the event itself is only
  /// created once step 2's "Next" is pressed - see event_create_screen.dart).
  Future<EventRecommendations> getRecommendations(PlannerEventType eventType) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/recommendations',
        queryParameters: {'eventType': eventType.toApi()},
      );
      return EventRecommendations.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// name/eventType/eventDate/location are all required by the backend
  /// (CreateEventRequest) - description/budget/guestCount stay optional.
  Future<PlannerEvent> createEvent({
    required String name,
    required PlannerEventType eventType,
    required DateTime eventDate,
    required String location,
    String? description,
    double? budget,
    int? guestCount,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/events',
        data: {
          'name': name,
          'eventType': eventType.toApi(),
          'eventDate': _dateOnly(eventDate),
          'location': location,
          if (description != null) 'description': description,
          if (budget != null) 'budget': budget,
          if (guestCount != null) 'guestCount': guestCount,
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

  /// Sets/changes date and/or location after creation - the only way to
  /// supply these once past the initial intake form (mirrors web's
  /// PlannerController#refreshSuppliers, which calls this same endpoint).
  /// Either argument can be null to leave that field as the event already
  /// has it; there's no way to clear a field back to null once set.
  Future<PlannerEvent> updateEventDetails(
    int eventId, {
    DateTime? eventDate,
    String? location,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/events/$eventId/details',
        data: {
          if (eventDate != null) 'eventDate': _dateOnly(eventDate),
          if (location != null) 'location': location,
        },
      );
      return PlannerEvent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Opts a suggested category in/out of active browsing, with an optional
  /// per-category budget earmark (EventSuggestedVendor#selected/#budget).
  Future<PlannerEvent> setSupplierTypeSelection(
    int eventId,
    String vendorType, {
    required bool selected,
    double? budget,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/events/$eventId/supplier-types/$vendorType',
        data: {
          'selected': selected,
          'budget': budget,
        },
      );
      return PlannerEvent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Removes a category from Search Result outright, deleting every
  /// checklist item under it too - distinct from setSupplierTypeSelection
  /// (selected: false) above, which deliberately leaves checklist items in
  /// place. This is the planner's one explicit "I don't want this category
  /// at all anymore" action (see backend EventService#removeCategorySelection).
  Future<PlannerEvent> removeSupplierType(int eventId, String vendorType) async {
    try {
      final response = await _apiClient.dio.delete('/api/v1/events/$eventId/supplier-types/$vendorType');
      return PlannerEvent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Bookmarks (or un-bookmarks) a specific supplier for an event, addressed
  /// by vendorUserId - same identifier ConversationApi/QuotationApi already
  /// use, since a storefront page only ever has that on hand, not the
  /// vendor's internal VendorProfile id. Creates a "Follow up with X"
  /// checklist item on bookmark.
  Future<PlannerEvent> setVendorBookmark(
    int eventId,
    int vendorUserId, {
    required bool bookmarked,
    String? category,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/events/$eventId/bookmarks/$vendorUserId',
        data: {'bookmarked': bookmarked, 'category': category},
      );
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
        data: {'status': status.toApi()},
      );
      return EventChecklistItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
