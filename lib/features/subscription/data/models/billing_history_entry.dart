import '../../../auth/data/models/plan_tier.dart';
import 'billing_source.dart';

/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.dto.VendorBillingHistoryEntryResponse}.
/// One row of the vendor's billing history (GET /api/v1/vendors/me/subscription/history).
class BillingHistoryEntry {
  final int id;
  final PlanTier plan;
  final BillingSource billingSource;
  // Null for a free-grant entry (VendorBillingHistoryService#recordFreeGrant) -
  // no payment occurred, so there's no amount/currency to record.
  final double? amount;
  final String? currency;
  final String? paypalTransactionId;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime occurredAt;

  const BillingHistoryEntry({
    required this.id,
    required this.plan,
    required this.billingSource,
    this.amount,
    this.currency,
    this.paypalTransactionId,
    this.periodStart,
    this.periodEnd,
    required this.occurredAt,
  });

  factory BillingHistoryEntry.fromJson(Map<String, dynamic> json) => BillingHistoryEntry(
        id: json['id'] as int,
        plan: PlanTierApi.fromApi(json['plan'] as String),
        billingSource: BillingSourceApi.fromApi(json['billingSource'] as String),
        amount: (json['amount'] as num?)?.toDouble(),
        currency: json['currency'] as String?,
        paypalTransactionId: json['paypalTransactionId'] as String?,
        periodStart: json['periodStart'] == null
            ? null
            : DateTime.parse(json['periodStart'] as String),
        periodEnd: json['periodEnd'] == null
            ? null
            : DateTime.parse(json['periodEnd'] as String),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
      );
}
