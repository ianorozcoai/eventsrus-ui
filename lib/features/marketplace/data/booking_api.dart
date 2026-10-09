import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/booking.dart';
import 'models/booking_status_event.dart';

class BookingApi {
  final ApiClient _apiClient;

  BookingApi(this._apiClient);

  /// Marks the vendor's Bookings nav badge as seen.
  Future<void> markSeen() async {
    try {
      await _apiClient.dio.put('/api/v1/vendors/me/bookings/mark-seen');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Booking> propose({
    required int eventId,
    double? price,
    DateTime? eventDatetime,
    String? agreementDetails,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/events/$eventId/vendors/me/bookings',
        data: {
          if (price != null) 'price': price,
          if (eventDatetime != null)
            'eventDatetime': eventDatetime.toUtc().toIso8601String(),
          if (agreementDetails != null) 'agreementDetails': agreementDetails,
        },
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Booking> approve(int bookingId) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/bookings/$bookingId/approve',
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Booking> decline(int bookingId) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/bookings/$bookingId/decline',
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Legacy planner-initiated path - converts a QUOTE_SENT/REVISION_SENT
  /// quotation into an AWAITING_PAYMENT booking. See the Booking model's
  /// doc comment for why today's real flow usually goes through
  /// QuotationApi.acceptBooking instead.
  Future<Booking> bookFromQuotation({
    required int quotationId,
    required double price,
    required DateTime eventDatetime,
    String? agreementDetails,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/quotations/$quotationId/book',
        data: {
          'price': price,
          'eventDatetime': eventDatetime.toUtc().toIso8601String(),
          if (agreementDetails != null) 'agreementDetails': agreementDetails,
        },
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Booking> submitPaymentScreenshot({
    required int bookingId,
    required List<int> screenshotBytes,
    required String screenshotFilename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'screenshot': MultipartFile.fromBytes(
          screenshotBytes,
          filename: screenshotFilename,
        ),
      });
      final response = await _apiClient.dio.post(
        '/api/v1/bookings/$bookingId/payment-screenshot',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Booking> acknowledgePayment({
    required int bookingId,
    required List<int> invoiceBytes,
    required String invoiceFilename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'invoice': MultipartFile.fromBytes(
          invoiceBytes,
          filename: invoiceFilename,
        ),
      });
      final response = await _apiClient.dio.post(
        '/api/v1/bookings/$bookingId/acknowledge-payment',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Booking> rejectPayment({
    required int bookingId,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/bookings/$bookingId/reject-payment',
        data: {'reason': reason},
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Either side can cancel from any non-terminal status with a mandatory
  /// reason.
  Future<Booking> cancel({
    required int bookingId,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/bookings/$bookingId/cancel',
        data: {'reason': reason},
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<BookingStatusEvent>> history(int bookingId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/bookings/$bookingId/history',
      );
      return (response.data as List)
          .map((e) => BookingStatusEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Booking>> listForEvent(int eventId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/events/$eventId/bookings',
      );
      return (response.data as List)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Booking>> listForVendor() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/bookings');
      return (response.data as List)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Booking>> listForPlanner() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/planners/me/bookings');
      return (response.data as List)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// "Unseen since I last opened this tab" count for a planner's per-event
  /// Bookings tab (see eventsrus-backend's EventTabBadgeController).
  Future<int> unseenCountForEvent(int eventId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/events/$eventId/bookings/unseen-count',
      );
      return (response.data as Map<String, dynamic>)['count'] as int;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markSeenForEvent(int eventId) async {
    try {
      await _apiClient.dio.put('/api/v1/events/$eventId/bookings/mark-seen');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
