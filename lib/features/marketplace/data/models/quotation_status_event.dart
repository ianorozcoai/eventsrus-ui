import 'quotation.dart';

/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.HistoryEntryType}.
enum HistoryEntryType { statusChange, attachment }

extension HistoryEntryTypeApi on HistoryEntryType {
  static HistoryEntryType fromApi(String value) {
    switch (value) {
      case 'STATUS_CHANGE':
        return HistoryEntryType.statusChange;
      case 'ATTACHMENT':
        return HistoryEntryType.attachment;
      default:
        throw FormatException('Unknown history entry type: $value');
    }
  }
}

/// Mirrors eventsrus-backend's {@code QuotationStatusEventResponse} - one row
/// of a quotation's full negotiation-to-booking timeline (see
/// QuotationApi.history).
class QuotationStatusEvent {
  final int id;
  final HistoryEntryType entryType;
  final QuotationStatus? fromStatus;
  final QuotationStatus? toStatus;
  final int? changedByUserId;
  final String? changedByName;
  final String? reason;
  final String? pdfUrl;
  final int? version;
  final double? quotedAmount;
  final DateTime? targetDate;
  final List<String> packageNames;
  final String? paymentScreenshotUrl;
  final String? invoiceUrl;
  final String? attachmentUrl;
  final String? attachmentFileType;
  final DateTime createdAt;

  const QuotationStatusEvent({
    required this.id,
    required this.entryType,
    this.fromStatus,
    this.toStatus,
    this.changedByUserId,
    this.changedByName,
    this.reason,
    this.pdfUrl,
    this.version,
    this.quotedAmount,
    this.targetDate,
    this.packageNames = const [],
    this.paymentScreenshotUrl,
    this.invoiceUrl,
    this.attachmentUrl,
    this.attachmentFileType,
    required this.createdAt,
  });

  factory QuotationStatusEvent.fromJson(Map<String, dynamic> json) => QuotationStatusEvent(
        id: json['id'] as int,
        entryType: HistoryEntryTypeApi.fromApi(json['entryType'] as String),
        fromStatus: json['fromStatus'] == null ? null : QuotationStatusApi.fromApi(json['fromStatus'] as String),
        toStatus: json['toStatus'] == null ? null : QuotationStatusApi.fromApi(json['toStatus'] as String),
        changedByUserId: json['changedByUserId'] as int?,
        changedByName: json['changedByName'] as String?,
        reason: json['reason'] as String?,
        pdfUrl: json['pdfUrl'] as String?,
        version: json['version'] as int?,
        quotedAmount: (json['quotedAmount'] as num?)?.toDouble(),
        targetDate: json['targetDate'] == null ? null : DateTime.parse(json['targetDate'] as String),
        packageNames: (json['packageNames'] as List?)?.map((e) => e as String).toList() ?? const [],
        paymentScreenshotUrl: json['paymentScreenshotUrl'] as String?,
        invoiceUrl: json['invoiceUrl'] as String?,
        attachmentUrl: json['attachmentUrl'] as String?,
        attachmentFileType: json['attachmentFileType'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
