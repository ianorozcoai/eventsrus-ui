import 'vendor_referral.dart';

/// Mirrors eventsrus-backend's {@code VendorReferralOverviewResponse}: this
/// vendor's own referral code/link, their running commission totals, and the
/// list of suppliers they've referred so far.
class VendorReferralOverview {
  final String referralCode;
  final String referralLink;
  final double totalPendingCommission;
  final double totalPaidCommission;
  final List<VendorReferral> referrals;

  const VendorReferralOverview({
    required this.referralCode,
    required this.referralLink,
    required this.totalPendingCommission,
    required this.totalPaidCommission,
    required this.referrals,
  });

  factory VendorReferralOverview.fromJson(Map<String, dynamic> json) => VendorReferralOverview(
        referralCode: json['referralCode'] as String? ?? '',
        referralLink: json['referralLink'] as String? ?? '',
        totalPendingCommission: (json['totalPendingCommission'] as num?)?.toDouble() ?? 0,
        totalPaidCommission: (json['totalPaidCommission'] as num?)?.toDouble() ?? 0,
        referrals: (json['referrals'] as List<dynamic>? ?? const [])
            .map((e) => VendorReferral.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
