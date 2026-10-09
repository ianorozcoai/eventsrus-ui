import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/billing_cycle.dart';
import 'models/billing_history_entry.dart';
import 'models/create_subscription_request.dart';
import 'models/create_subscription_response.dart';
import 'models/subscription_status_response.dart';

class SubscriptionApi {
  final ApiClient _apiClient;

  SubscriptionApi(this._apiClient);

  Future<CreateSubscriptionResponse> createSubscription(
    CreateSubscriptionRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/subscription',
        data: request.toJson(),
      );
      return CreateSubscriptionResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SubscriptionStatusResponse> confirmSubscription(int vendorSubscriptionId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/vendors/me/subscription/confirm',
        queryParameters: {'vendorSubscriptionId': vendorSubscriptionId},
      );
      return SubscriptionStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<SubscriptionStatusResponse> getStatus() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/subscription');
      return SubscriptionStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// "Upload Payment Screenshot" on the GCash popup - manual payment
  /// verification flow (no payment API). The resulting status reflects the
  /// GCash grant immediately (plan becomes non-null with
  /// gcashAwaitingVerification=true) even though an admin hasn't reviewed
  /// it yet - see SubscriptionStatusResponse's doc comments.
  Future<SubscriptionStatusResponse> submitGcashPayment({
    required BillingCycle billingCycle,
    required PlatformFile screenshot,
    String? vendorRemarks,
  }) async {
    final formData = FormData.fromMap({
      'billingCycle': billingCycle.toApi(),
      'screenshot': MultipartFile.fromBytes(screenshot.bytes!, filename: screenshot.name),
      if (vendorRemarks != null && vendorRemarks.trim().isNotEmpty)
        'vendorRemarks': vendorRemarks.trim(),
    });

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/subscription/gcash-payment',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return SubscriptionStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<BillingHistoryEntry>> getHistory() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/subscription/history');
      return (response.data as List)
          .map((json) => BillingHistoryEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
