import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/booking_amendment.dart';

/// Client for the post-booking "change order" flow - either side on an
/// already-BOOKED booking can propose a price/date/details/packages change,
/// the other side accepts or rejects it, and the proposer can withdraw it
/// while it's still pending. See BookingAmendmentController (backend).
class BookingAmendmentApi {
  final ApiClient _apiClient;

  BookingAmendmentApi(this._apiClient);

  Future<BookingAmendment> propose({
    required int bookingId,
    required String note,
    double? newPrice,
    DateTime? newEventDatetime,
    String? newAgreementDetails,
    List<int>? newPackageIds,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/bookings/$bookingId/amendments',
        data: {
          'note': note,
          if (newPrice != null) 'newPrice': newPrice,
          if (newEventDatetime != null) 'newEventDatetime': newEventDatetime.toUtc().toIso8601String(),
          if (newAgreementDetails != null) 'newAgreementDetails': newAgreementDetails,
          if (newPackageIds != null && newPackageIds.isNotEmpty) 'newPackageIds': newPackageIds,
        },
      );
      return BookingAmendment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<BookingAmendment>> listForBooking(int bookingId) async {
    try {
      final response = await _apiClient.dio.get('/api/v1/bookings/$bookingId/amendments');
      return (response.data as List).map((e) => BookingAmendment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<BookingAmendment> accept(int amendmentId) async {
    try {
      final response = await _apiClient.dio.put('/api/v1/amendments/$amendmentId/accept');
      return BookingAmendment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<BookingAmendment> reject(int amendmentId) async {
    try {
      final response = await _apiClient.dio.put('/api/v1/amendments/$amendmentId/reject');
      return BookingAmendment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<BookingAmendment> withdraw(int amendmentId) async {
    try {
      final response = await _apiClient.dio.put('/api/v1/amendments/$amendmentId/withdraw');
      return BookingAmendment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
