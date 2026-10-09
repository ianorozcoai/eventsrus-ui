import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/review.dart';

/// Planner review of a completed booking (see eventsrus-backend's
/// ReviewController). Listing a vendor's reviews has no dedicated endpoint -
/// both the public storefront and the vendor's own "my reviews" view read
/// them off the vendor's public profile (see VendorDirectoryApi.getProfile),
/// same as eventsrus-web's vendor/storefront.html preview page.
class ReviewApi {
  final ApiClient _apiClient;

  ReviewApi(this._apiClient);

  /// First review on [bookingId]. Only valid once Booking.canReview is true.
  Future<Review> submit({required int bookingId, required int rating, required String comment}) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/bookings/$bookingId/review',
        data: {'rating': rating, 'comment': comment},
      );
      return Review.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Edits the planner's own existing review (Booking.reviewId).
  Future<Review> update({required int reviewId, required int rating, required String comment}) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/reviews/$reviewId',
        data: {'rating': rating, 'comment': comment},
      );
      return Review.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
