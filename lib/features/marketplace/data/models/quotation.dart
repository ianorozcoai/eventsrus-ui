import '../../../planner/data/models/planner_event_type.dart';

/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.QuotationStatus} -
/// the full negotiation-to-booking lifecycle (see that enum's Javadoc for the
/// authoritative description of each state and which service method moves
/// between them).
enum QuotationStatus {
  requestForQuote,
  quoteSent,
  revisionRequested,
  revisionSent,
  quoteAccepted,
  pendingDeposit,
  paymentReview,
  paymentRejected,
  booked,
  declined,
  cancelled,
}

extension QuotationStatusApi on QuotationStatus {
  String toApi() {
    switch (this) {
      case QuotationStatus.requestForQuote:
        return 'REQUEST_FOR_QUOTE';
      case QuotationStatus.quoteSent:
        return 'QUOTE_SENT';
      case QuotationStatus.revisionRequested:
        return 'REVISION_REQUESTED';
      case QuotationStatus.revisionSent:
        return 'REVISION_SENT';
      case QuotationStatus.quoteAccepted:
        return 'QUOTE_ACCEPTED';
      case QuotationStatus.pendingDeposit:
        return 'PENDING_DEPOSIT';
      case QuotationStatus.paymentReview:
        return 'PAYMENT_REVIEW';
      case QuotationStatus.paymentRejected:
        return 'PAYMENT_REJECTED';
      case QuotationStatus.booked:
        return 'BOOKED';
      case QuotationStatus.declined:
        return 'DECLINED';
      case QuotationStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case QuotationStatus.requestForQuote:
        return 'Awaiting Quote';
      case QuotationStatus.quoteSent:
        return 'Quote Sent';
      case QuotationStatus.revisionRequested:
        return 'Revision Requested';
      case QuotationStatus.revisionSent:
        return 'Revision Sent';
      case QuotationStatus.quoteAccepted:
        return 'Quote Accepted';
      case QuotationStatus.pendingDeposit:
        return 'Pending Deposit';
      case QuotationStatus.paymentReview:
        return 'Payment Review';
      case QuotationStatus.paymentRejected:
        return 'Payment Rejected';
      case QuotationStatus.booked:
        return 'Booked';
      case QuotationStatus.declined:
        return 'Declined';
      case QuotationStatus.cancelled:
        return 'Cancelled';
    }
  }

  static QuotationStatus fromApi(String value) {
    switch (value) {
      case 'REQUEST_FOR_QUOTE':
        return QuotationStatus.requestForQuote;
      case 'QUOTE_SENT':
        return QuotationStatus.quoteSent;
      case 'REVISION_REQUESTED':
        return QuotationStatus.revisionRequested;
      case 'REVISION_SENT':
        return QuotationStatus.revisionSent;
      case 'QUOTE_ACCEPTED':
        return QuotationStatus.quoteAccepted;
      case 'PENDING_DEPOSIT':
        return QuotationStatus.pendingDeposit;
      case 'PAYMENT_REVIEW':
        return QuotationStatus.paymentReview;
      case 'PAYMENT_REJECTED':
        return QuotationStatus.paymentRejected;
      case 'BOOKED':
        return QuotationStatus.booked;
      case 'DECLINED':
        return QuotationStatus.declined;
      case 'CANCELLED':
        return QuotationStatus.cancelled;
      default:
        throw FormatException('Unknown quotation status: $value');
    }
  }
}

/// Mirrors eventsrus-backend's {@code QuotationResponse} field-for-field.
class Quotation {
  final int id;
  final int eventId;
  final String? eventName;
  final PlannerEventType? eventType;
  final int vendorUserId;
  final String? vendorBusinessName;
  final String? vendorSlug;
  final String? cancellationPolicyUrl;
  final String? refundTermsUrl;
  final int plannerUserId;
  final String? plannerName;
  final DateTime? targetDate;
  final String? requestMessage;
  final QuotationStatus status;
  final int version;
  final double? quotedAmount;
  final String? pdfUrl;
  final DateTime? respondedAt;
  final DateTime? acceptedAt;
  final String? paymentScreenshotUrl;
  final String? paymentRejectionReason;
  final DateTime createdAt;
  final List<int> packageIds;
  final List<String> packageNames;
  final DateTime? declinedAt;
  final List<String> referenceImageUrls;
  final List<String> responseImageUrls;

  const Quotation({
    required this.id,
    required this.eventId,
    this.eventName,
    this.eventType,
    required this.vendorUserId,
    this.vendorBusinessName,
    this.vendorSlug,
    this.cancellationPolicyUrl,
    this.refundTermsUrl,
    required this.plannerUserId,
    this.plannerName,
    this.targetDate,
    this.requestMessage,
    required this.status,
    this.version = 1,
    this.quotedAmount,
    this.pdfUrl,
    this.respondedAt,
    this.acceptedAt,
    this.paymentScreenshotUrl,
    this.paymentRejectionReason,
    required this.createdAt,
    this.packageIds = const [],
    this.packageNames = const [],
    this.declinedAt,
    this.referenceImageUrls = const [],
    this.responseImageUrls = const [],
  });

  /// Whether this quotation is still open to vendor/planner negotiation
  /// (i.e. hasn't reached QUOTE_ACCEPTED or beyond, and isn't closed out).
  bool get isOpenNegotiation => const {
    QuotationStatus.requestForQuote,
    QuotationStatus.quoteSent,
    QuotationStatus.revisionRequested,
    QuotationStatus.revisionSent,
  }.contains(status);

  factory Quotation.fromJson(Map<String, dynamic> json) => Quotation(
    id: json['id'] as int,
    eventId: json['eventId'] as int,
    eventName: json['eventName'] as String?,
    eventType: json['eventType'] == null
        ? null
        : PlannerEventTypeApi.fromApi(json['eventType'] as String),
    vendorUserId: json['vendorUserId'] as int,
    vendorBusinessName: json['vendorBusinessName'] as String?,
    vendorSlug: json['vendorSlug'] as String?,
    cancellationPolicyUrl: json['cancellationPolicyUrl'] as String?,
    refundTermsUrl: json['refundTermsUrl'] as String?,
    plannerUserId: json['plannerUserId'] as int,
    plannerName: json['plannerName'] as String?,
    targetDate: json['targetDate'] == null
        ? null
        : DateTime.parse(json['targetDate'] as String),
    requestMessage: json['requestMessage'] as String?,
    status: QuotationStatusApi.fromApi(json['status'] as String),
    version: json['version'] as int? ?? 1,
    quotedAmount: (json['quotedAmount'] as num?)?.toDouble(),
    pdfUrl: json['pdfUrl'] as String?,
    respondedAt: json['respondedAt'] == null
        ? null
        : DateTime.parse(json['respondedAt'] as String),
    acceptedAt: json['acceptedAt'] == null
        ? null
        : DateTime.parse(json['acceptedAt'] as String),
    paymentScreenshotUrl: json['paymentScreenshotUrl'] as String?,
    paymentRejectionReason: json['paymentRejectionReason'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    packageIds:
        (json['packageIds'] as List?)?.map((e) => e as int).toList() ??
        const [],
    packageNames:
        (json['packageNames'] as List?)?.map((e) => e as String).toList() ??
        const [],
    declinedAt: json['declinedAt'] == null
        ? null
        : DateTime.parse(json['declinedAt'] as String),
    referenceImageUrls:
        (json['referenceImageUrls'] as List?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    responseImageUrls:
        (json['responseImageUrls'] as List?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
  );
}
