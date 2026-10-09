/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.AmendmentStatus}.
enum AmendmentStatus { pending, accepted, rejected, withdrawn }

extension AmendmentStatusApi on AmendmentStatus {
  String get label {
    switch (this) {
      case AmendmentStatus.pending:
        return 'Pending';
      case AmendmentStatus.accepted:
        return 'Accepted';
      case AmendmentStatus.rejected:
        return 'Rejected';
      case AmendmentStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  static AmendmentStatus fromApi(String value) {
    switch (value) {
      case 'PENDING':
        return AmendmentStatus.pending;
      case 'ACCEPTED':
        return AmendmentStatus.accepted;
      case 'REJECTED':
        return AmendmentStatus.rejected;
      case 'WITHDRAWN':
        return AmendmentStatus.withdrawn;
      default:
        throw FormatException('Unknown amendment status: $value');
    }
  }
}

/// Mirrors eventsrus-backend's {@code BookingAmendmentResponse} - a change
/// order (price/date/details/packages) proposed against an already-BOOKED
/// booking by either side; the other side accepts or rejects it, and the
/// proposer can withdraw it while still pending (see BookingAmendmentApi).
class BookingAmendment {
  final int id;
  final int bookingId;
  final int proposedByUserId;
  final String? proposedByName;
  final double? newPrice;
  final DateTime? newEventDatetime;
  final String? newAgreementDetails;
  final List<int> newPackageIds;
  final List<String> newPackageNames;
  final String note;
  final AmendmentStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const BookingAmendment({
    required this.id,
    required this.bookingId,
    required this.proposedByUserId,
    this.proposedByName,
    this.newPrice,
    this.newEventDatetime,
    this.newAgreementDetails,
    this.newPackageIds = const [],
    this.newPackageNames = const [],
    required this.note,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory BookingAmendment.fromJson(Map<String, dynamic> json) => BookingAmendment(
        id: json['id'] as int,
        bookingId: json['bookingId'] as int,
        proposedByUserId: json['proposedByUserId'] as int,
        proposedByName: json['proposedByName'] as String?,
        newPrice: (json['newPrice'] as num?)?.toDouble(),
        newEventDatetime:
            json['newEventDatetime'] == null ? null : DateTime.parse(json['newEventDatetime'] as String),
        newAgreementDetails: json['newAgreementDetails'] as String?,
        newPackageIds: (json['newPackageIds'] as List?)?.map((e) => e as int).toList() ?? const [],
        newPackageNames: (json['newPackageNames'] as List?)?.map((e) => e as String).toList() ?? const [],
        note: json['note'] as String? ?? '',
        status: AmendmentStatusApi.fromApi(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] == null ? null : DateTime.parse(json['resolvedAt'] as String),
      );
}
