import 'booking.dart';

/// Mirrors eventsrus-backend's {@code BookingStatusEventResponse} - one row
/// of a booking's status timeline (see BookingApi.history).
class BookingStatusEvent {
  final int id;
  final BookingStatus? fromStatus;
  final BookingStatus? toStatus;
  final int? changedByUserId;
  final String? changedByName;
  final String? reason;
  final DateTime createdAt;

  const BookingStatusEvent({
    required this.id,
    this.fromStatus,
    this.toStatus,
    this.changedByUserId,
    this.changedByName,
    this.reason,
    required this.createdAt,
  });

  factory BookingStatusEvent.fromJson(Map<String, dynamic> json) => BookingStatusEvent(
        id: json['id'] as int,
        fromStatus: json['fromStatus'] == null ? null : BookingStatusApi.fromApi(json['fromStatus'] as String),
        toStatus: json['toStatus'] == null ? null : BookingStatusApi.fromApi(json['toStatus'] as String),
        changedByUserId: json['changedByUserId'] as int?,
        changedByName: json['changedByName'] as String?,
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
