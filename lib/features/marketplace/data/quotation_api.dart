import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/quotation.dart';
import 'models/quotation_status_event.dart';

class QuotationApi {
  final ApiClient _apiClient;

  QuotationApi(this._apiClient);

  Future<Quotation> requestQuotation({
    required int eventId,
    required int vendorUserId,
    required String plannerName,
    DateTime? targetDate,
    required String message,
    List<int>? packageIds,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/events/$eventId/vendors/$vendorUserId/quotations',
        data: {
          'plannerName': plannerName,
          if (targetDate != null) 'targetDate': _dateOnly(targetDate),
          'message': message,
          if (packageIds != null && packageIds.isNotEmpty)
            'packageIds': packageIds,
        },
      );
      return Quotation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// A vendor starting a brand-new quote directly from a chat thread, for
  /// when negotiation happened in chat with no prior storefront request -
  /// no UI wires this up yet (it belongs with the chat feature screens),
  /// but the client method is here so the full QuotationController surface
  /// has a Dio counterpart.
  Future<Quotation> createFromChat({
    required int eventId,
    required List<int> pdfBytes,
    required String pdfFilename,
    required double quotedAmount,
    DateTime? targetDate,
    String? message,
    List<int>? packageIds,
    List<({List<int> bytes, String filename})> images = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'pdf': MultipartFile.fromBytes(pdfBytes, filename: pdfFilename),
        'quotedAmount': quotedAmount,
        if (targetDate != null) 'targetDate': _dateOnly(targetDate),
        if (message != null && message.isNotEmpty) 'message': message,
        if (packageIds != null && packageIds.isNotEmpty)
          'packageIds': packageIds,
        if (images.isNotEmpty)
          'images': [
            for (final image in images)
              MultipartFile.fromBytes(image.bytes, filename: image.filename),
          ],
      });
      final response = await _apiClient.dio.post(
        '/api/v1/events/$eventId/vendor-quotations',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Quotation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Quotation>> listForEvent(int eventId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/events/$eventId/quotations',
      );
      return (response.data as List)
          .map((e) => Quotation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Quotation>> listForVendor() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/vendors/me/quotations',
      );
      return (response.data as List)
          .map((e) => Quotation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Quotation>> listForPlanner() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/planners/me/quotations',
      );
      return (response.data as List)
          .map((e) => Quotation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Marks the vendor's Quotations nav badge as seen - call this when the
  /// vendor's quotations list screen is opened (mirrors VendorController's
  /// behavior loading that page).
  Future<void> markSeen() async {
    try {
      await _apiClient.dio.put('/api/v1/vendors/me/quotations/mark-seen');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Vendor sends out a quote (initial response to REQUEST_FOR_QUOTE, or a
  /// resend after REVISION_REQUESTED) - moves the quotation to QUOTE_SENT/
  /// REVISION_SENT and bumps its version.
  Future<Quotation> respondWithPdf({
    required int quotationId,
    required List<int> pdfBytes,
    required String pdfFilename,
    required double quotedAmount,
    String? message,
    List<({List<int> bytes, String filename})> images = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'pdf': MultipartFile.fromBytes(pdfBytes, filename: pdfFilename),
        'quotedAmount': quotedAmount,
        if (message != null && message.isNotEmpty) 'message': message,
        if (images.isNotEmpty)
          'images': [
            for (final image in images)
              MultipartFile.fromBytes(image.bytes, filename: image.filename),
          ],
      });
      final response = await _apiClient.dio.post(
        '/api/v1/vendors/me/quotations/$quotationId/respond',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Quotation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Planner formally closes out a quotation without booking - only
  /// reachable pre-acceptance.
  Future<Quotation> decline(int quotationId) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/quotations/$quotationId/decline',
      );
      return Quotation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Planner asks for changes to the last sent quote - moves it to
  /// REVISION_REQUESTED.
  Future<Quotation> requestRevision({
    required int quotationId,
    required String message,
    DateTime? targetDate,
    List<({List<int> bytes, String filename})> images = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'message': message,
        if (targetDate != null) 'targetDate': _dateOnly(targetDate),
        if (images.isNotEmpty)
          'images': [
            for (final image in images)
              MultipartFile.fromBytes(image.bytes, filename: image.filename),
          ],
      });
      final response = await _apiClient.dio.post(
        '/api/v1/quotations/$quotationId/revise',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Quotation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Planner accepts a QUOTE_SENT/REVISION_SENT version - auto-resolves to
  /// PENDING_DEPOSIT or PAYMENT_REVIEW (if a screenshot is attached here).
  /// [acceptedVersion] null means "accept the current/latest version".
  Future<Quotation> acceptQuote({
    required int quotationId,
    int? acceptedVersion,
    String? message,
    List<int>? screenshotBytes,
    String? screenshotFilename,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (acceptedVersion != null) 'acceptedVersion': acceptedVersion,
        if (message != null && message.isNotEmpty) 'message': message,
        if (screenshotBytes != null)
          'screenshot': MultipartFile.fromBytes(
            screenshotBytes,
            filename: screenshotFilename ?? 'screenshot.jpg',
          ),
      });
      final response = await _apiClient.dio.post(
        '/api/v1/quotations/$quotationId/accept',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Quotation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Standalone payment screenshot upload - for a planner who accepted
  /// without one and comes back once ready to pay, or resubmitting after a
  /// PAYMENT_REJECTED. Moves the quotation to PAYMENT_REVIEW.
  Future<Quotation> submitPaymentScreenshot({
    required int quotationId,
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
        '/api/v1/quotations/$quotationId/payment-screenshot',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Quotation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Vendor rejects the planner's payment screenshot - sends it back to
  /// PAYMENT_REJECTED so the planner can resubmit.
  Future<Quotation> rejectPayment({
    required int quotationId,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/quotations/$quotationId/reject-payment',
        data: {'reason': reason},
      );
      return Quotation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Vendor verifies payment and confirms the booking - creates the actual
  /// Booking row for the first time, and locks this quotation at BOOKED.
  Future<Quotation> acceptBooking({
    required int quotationId,
    String? confirmationMessage,
    required String paymentType,
    required List<int> invoiceBytes,
    required String invoiceFilename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'paymentType': paymentType,
        'invoice': MultipartFile.fromBytes(
          invoiceBytes,
          filename: invoiceFilename,
        ),
        if (confirmationMessage != null && confirmationMessage.isNotEmpty)
          'confirmationMessage': confirmationMessage,
      });
      final response = await _apiClient.dio.post(
        '/api/v1/quotations/$quotationId/accept-booking',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Quotation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// The full negotiation-to-booking timeline for this quotation.
  Future<List<QuotationStatusEvent>> history(int quotationId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/quotations/$quotationId/history',
      );
      return (response.data as List)
          .map((e) => QuotationStatusEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// A free-standing image/PDF either side can send at any time - doesn't
  /// change the quotation's status.
  Future<void> addAttachment({
    required int quotationId,
    required List<int> fileBytes,
    required String filename,
    String? message,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: filename),
        if (message != null && message.isNotEmpty) 'message': message,
      });
      await _apiClient.dio.post(
        '/api/v1/quotations/$quotationId/attachments',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// "Unseen since I last opened this tab" count for a planner's per-event
  /// Quotations tab (see eventsrus-backend's EventTabBadgeController).
  Future<int> unseenCountForEvent(int eventId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/events/$eventId/quotations/unseen-count',
      );
      return (response.data as Map<String, dynamic>)['count'] as int;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> markSeenForEvent(int eventId) async {
    try {
      await _apiClient.dio.put('/api/v1/events/$eventId/quotations/mark-seen');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
