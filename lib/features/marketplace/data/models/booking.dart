/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.BookingStatus}.
///
/// PROPOSED/APPROVED/DECLINED/CANCELLED is the vendor-initiated "cold
/// proposal" path (BookingApi.propose/approve/decline, independent of any
/// quotation). AWAITING_PAYMENT/PAYMENT_SUBMITTED/BOOKED/PAYMENT_REJECTED is
/// the legacy planner-initiated path born from a RESPONDED (now QUOTE_SENT/
/// REVISION_SENT) quotation via BookingApi.bookFromQuotation - today's real
/// quotation-to-booking flow instead goes entirely through
/// QuotationApi.acceptBooking, which creates the Booking already at BOOKED,
/// so AWAITING_PAYMENT/PAYMENT_SUBMITTED are rarely reached in practice but
/// are still fully supported here since the backend endpoints exist.
enum BookingStatus {
  proposed,
  approved,
  declined,
  cancelled,
  awaitingPayment,
  paymentSubmitted,
  booked,
  paymentRejected,
}

extension BookingStatusApi on BookingStatus {
  String toApi() {
    switch (this) {
      case BookingStatus.proposed:
        return 'PROPOSED';
      case BookingStatus.approved:
        return 'APPROVED';
      case BookingStatus.declined:
        return 'DECLINED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.awaitingPayment:
        return 'AWAITING_PAYMENT';
      case BookingStatus.paymentSubmitted:
        return 'PAYMENT_SUBMITTED';
      case BookingStatus.booked:
        return 'BOOKED';
      case BookingStatus.paymentRejected:
        return 'PAYMENT_REJECTED';
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.proposed:
        return 'Awaiting Approval';
      case BookingStatus.approved:
        return 'Approved';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.awaitingPayment:
        return 'Awaiting Payment';
      case BookingStatus.paymentSubmitted:
        return 'Payment Submitted';
      case BookingStatus.booked:
        return 'Booked';
      case BookingStatus.paymentRejected:
        return 'Payment Rejected';
    }
  }

  static BookingStatus fromApi(String value) {
    switch (value) {
      case 'PROPOSED':
        return BookingStatus.proposed;
      case 'APPROVED':
        return BookingStatus.approved;
      case 'DECLINED':
        return BookingStatus.declined;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'AWAITING_PAYMENT':
        return BookingStatus.awaitingPayment;
      case 'PAYMENT_SUBMITTED':
        return BookingStatus.paymentSubmitted;
      case 'BOOKED':
        return BookingStatus.booked;
      case 'PAYMENT_REJECTED':
        return BookingStatus.paymentRejected;
      default:
        throw FormatException('Unknown booking status: $value');
    }
  }
}

/// Mirrors eventsrus-backend's {@code BookingResponse} field-for-field.
class Booking {
  final int id;
  final int eventId;
  final String? eventName;
  final int vendorUserId;
  final String? vendorBusinessName;
  final String? vendorSlug;
  final String? cancellationPolicyUrl;
  final String? refundTermsUrl;
  final int plannerUserId;
  final String? plannerName;
  final int? quotationId;
  final double? price;
  final DateTime? eventDatetime;
  final String? agreementDetails;
  final BookingStatus status;
  final DateTime proposedAt;
  final DateTime? respondedAt;
  final String? paymentScreenshotUrl;
  final DateTime? paymentScreenshotUploadedAt;
  final DateTime? paymentAcknowledgedAt;
  final String? paymentRejectionReason;
  final String? invoiceUrl;
  final DateTime? invoiceUploadedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final int? cancelledByUserId;
  final bool hasPendingAmendment;
  final bool canReview;
  final int? reviewId;
  final int? reviewRating;
  final String? reviewComment;

  const Booking({
    required this.id,
    required this.eventId,
    this.eventName,
    required this.vendorUserId,
    this.vendorBusinessName,
    this.vendorSlug,
    this.cancellationPolicyUrl,
    this.refundTermsUrl,
    required this.plannerUserId,
    this.plannerName,
    this.quotationId,
    this.price,
    this.eventDatetime,
    this.agreementDetails,
    required this.status,
    required this.proposedAt,
    this.respondedAt,
    this.paymentScreenshotUrl,
    this.paymentScreenshotUploadedAt,
    this.paymentAcknowledgedAt,
    this.paymentRejectionReason,
    this.invoiceUrl,
    this.invoiceUploadedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledByUserId,
    this.hasPendingAmendment = false,
    this.canReview = false,
    this.reviewId,
    this.reviewRating,
    this.reviewComment,
  });

  bool get isTerminal => status == BookingStatus.declined || status == BookingStatus.cancelled;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as int,
        eventId: json['eventId'] as int,
        eventName: json['eventName'] as String?,
        vendorUserId: json['vendorUserId'] as int,
        vendorBusinessName: json['vendorBusinessName'] as String?,
        vendorSlug: json['vendorSlug'] as String?,
        cancellationPolicyUrl: json['cancellationPolicyUrl'] as String?,
        refundTermsUrl: json['refundTermsUrl'] as String?,
        plannerUserId: json['plannerUserId'] as int,
        plannerName: json['plannerName'] as String?,
        quotationId: json['quotationId'] as int?,
        price: (json['price'] as num?)?.toDouble(),
        eventDatetime: json['eventDatetime'] == null ? null : DateTime.parse(json['eventDatetime'] as String),
        agreementDetails: json['agreementDetails'] as String?,
        status: BookingStatusApi.fromApi(json['status'] as String),
        proposedAt: DateTime.parse(json['proposedAt'] as String),
        respondedAt: json['respondedAt'] == null ? null : DateTime.parse(json['respondedAt'] as String),
        paymentScreenshotUrl: json['paymentScreenshotUrl'] as String?,
        paymentScreenshotUploadedAt: json['paymentScreenshotUploadedAt'] == null
            ? null
            : DateTime.parse(json['paymentScreenshotUploadedAt'] as String),
        paymentAcknowledgedAt:
            json['paymentAcknowledgedAt'] == null ? null : DateTime.parse(json['paymentAcknowledgedAt'] as String),
        paymentRejectionReason: json['paymentRejectionReason'] as String?,
        invoiceUrl: json['invoiceUrl'] as String?,
        invoiceUploadedAt: json['invoiceUploadedAt'] == null ? null : DateTime.parse(json['invoiceUploadedAt'] as String),
        cancelledAt: json['cancelledAt'] == null ? null : DateTime.parse(json['cancelledAt'] as String),
        cancellationReason: json['cancellationReason'] as String?,
        cancelledByUserId: json['cancelledByUserId'] as int?,
        hasPendingAmendment: json['hasPendingAmendment'] as bool? ?? false,
        canReview: json['canReview'] as bool? ?? false,
        reviewId: json['reviewId'] as int?,
        reviewRating: json['reviewRating'] as int?,
        reviewComment: json['reviewComment'] as String?,
      );
}
