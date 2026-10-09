/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.ReferralStatus}.
///
/// - pending: the referred vendor onboarded with this vendor's referral code
///   but hasn't paid for anything yet (still on free trial, or not
///   subscribed).
/// - converted: the referred vendor's subscription is now backed by a real
///   PayPal payment - a commission is owed but not yet paid out.
/// - commissionPaid: an admin has manually marked the commission as paid out.
///   There's no automated disbursement.
enum ReferralStatus { pending, converted, commissionPaid }

extension ReferralStatusApi on ReferralStatus {
  String get label {
    switch (this) {
      case ReferralStatus.pending:
        return 'Pending';
      case ReferralStatus.converted:
        return 'Converted, not yet paid';
      case ReferralStatus.commissionPaid:
        return 'Paid';
    }
  }

  static ReferralStatus fromApi(String value) {
    switch (value) {
      case 'PENDING':
        return ReferralStatus.pending;
      case 'CONVERTED':
        return ReferralStatus.converted;
      case 'COMMISSION_PAID':
        return ReferralStatus.commissionPaid;
      default:
        throw FormatException('Unknown referral status: $value');
    }
  }
}

/// Mirrors eventsrus-backend's {@code VendorReferralResponse}: one supplier
/// who signed up using this vendor's referral code, and the commission owed
/// (or paid) for that referral.
class VendorReferral {
  final int id;
  final String referredBusinessName;
  final ReferralStatus status;
  final double? commissionAmount;
  final DateTime createdAt;
  final DateTime? convertedAt;
  final DateTime? paidAt;
  final String? paymentRemarks;
  final String? paymentProofUrl;

  const VendorReferral({
    required this.id,
    required this.referredBusinessName,
    required this.status,
    this.commissionAmount,
    required this.createdAt,
    this.convertedAt,
    this.paidAt,
    this.paymentRemarks,
    this.paymentProofUrl,
  });

  factory VendorReferral.fromJson(Map<String, dynamic> json) => VendorReferral(
        id: json['id'] as int,
        referredBusinessName: json['referredBusinessName'] as String? ?? '',
        status: ReferralStatusApi.fromApi(json['status'] as String),
        commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        convertedAt: json['convertedAt'] == null ? null : DateTime.parse(json['convertedAt'] as String),
        paidAt: json['paidAt'] == null ? null : DateTime.parse(json['paidAt'] as String),
        paymentRemarks: json['paymentRemarks'] as String?,
        paymentProofUrl: json['paymentProofUrl'] as String?,
      );
}
