import '../../../auth/data/models/plan_tier.dart';
import 'billing_cycle.dart';
import 'billing_source.dart';

/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.dto.SubscriptionStatusResponse}.
class SubscriptionStatusResponse {
  // Backend user id - used as the RevenueCat app_user_id for Google Play purchases.
  final int? userId;
  final PlanTier? plan;
  final DateTime? expiresAt;
  final bool expiringSoon;
  final bool expired;
  final bool inGracePeriod;
  final DateTime? graceEndsAt;
  final int monthlyPrice;
  final int quarterlyPrice;
  final int semiAnnualPrice;
  final int annualPrice;
  final BillingSource? billingSource;
  final String? monthlyPlanId;
  final String? quarterlyPlanId;
  final String? semiAnnualPlanId;
  final String? annualPlanId;
  // True exactly once, the first time this vendor's plan becomes genuinely
  // active. Mobile doesn't show the "Welcome to PRO" popup yet (no screen
  // calls POST /welcome-shown) - this field is parsed and kept for parity
  // but currently unused, see plan_selection_screen.dart's doc comment.
  final bool showWelcomePopup;
  final bool gcashAwaitingVerification;
  // True once, right after sign-up, while the supplier is on the free trial: show the
  // "Welcome to EventsRUs" message (Subscribe now / Continue with the free trial).
  final bool showTrialWelcome;
  final bool gcashRejected;
  final String? gcashRejectionReason;

  const SubscriptionStatusResponse({
    this.userId,
    required this.plan,
    required this.expiresAt,
    required this.expiringSoon,
    required this.expired,
    this.inGracePeriod = false,
    this.graceEndsAt,
    this.monthlyPrice = 0,
    this.quarterlyPrice = 0,
    this.semiAnnualPrice = 0,
    this.annualPrice = 0,
    this.billingSource,
    this.monthlyPlanId,
    this.quarterlyPlanId,
    this.semiAnnualPlanId,
    this.annualPlanId,
    this.showWelcomePopup = false,
    this.gcashAwaitingVerification = false,
    this.showTrialWelcome = false,
    this.gcashRejected = false,
    this.gcashRejectionReason,
  });

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatusResponse(
        userId: (json['userId'] as num?)?.toInt(),
        plan: PlanTierApi.fromApiNullable(json['plan'] as String?),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.parse(json['expiresAt'] as String),
        expiringSoon: json['expiringSoon'] as bool? ?? false,
        expired: json['expired'] as bool? ?? false,
        inGracePeriod: json['inGracePeriod'] as bool? ?? false,
        graceEndsAt: json['graceEndsAt'] == null
            ? null
            : DateTime.parse(json['graceEndsAt'] as String),
        monthlyPrice: json['monthlyPrice'] as int? ?? 0,
        quarterlyPrice: json['quarterlyPrice'] as int? ?? 0,
        semiAnnualPrice: json['semiAnnualPrice'] as int? ?? 0,
        annualPrice: json['annualPrice'] as int? ?? 0,
        billingSource: BillingSourceApi.fromApiNullable(json['billingSource'] as String?),
        monthlyPlanId: json['monthlyPlanId'] as String?,
        quarterlyPlanId: json['quarterlyPlanId'] as String?,
        semiAnnualPlanId: json['semiAnnualPlanId'] as String?,
        annualPlanId: json['annualPlanId'] as String?,
        showWelcomePopup: json['showWelcomePopup'] as bool? ?? false,
        gcashAwaitingVerification: json['gcashAwaitingVerification'] as bool? ?? false,
        showTrialWelcome: json['showTrialWelcome'] as bool? ?? false,
        gcashRejected: json['gcashRejected'] as bool? ?? false,
        gcashRejectionReason: json['gcashRejectionReason'] as String?,
      );

  /// True for a supplier still on the free period that came with signing up (or a promo code):
  /// the server reports it as the grace period of a free grant. It must be worded as a free
  /// trial, not as an expired subscription - that wording is only for suppliers who stopped paying.
  bool get onFreeTrial => inGracePeriod && graceEndsAt != null && billingSource == BillingSource.freeGrant;

  /// Whole days (rounded up, at least 1 while it still runs) left of the free trial, or null.
  int? get freeTrialDaysLeft {
    if (!onFreeTrial) return null;
    final left = graceEndsAt!.difference(DateTime.now());
    if (left.isNegative) return 0;
    return (left.inMinutes / (24 * 60)).ceil().clamp(1, 100000);
  }

  /// The flat per-cycle total price (in PHP) for [cycle], from whichever of
  /// the four `*Price` fields matches.
  int priceFor(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return monthlyPrice;
      case BillingCycle.quarterly:
        return quarterlyPrice;
      case BillingCycle.semiAnnual:
        return semiAnnualPrice;
      case BillingCycle.annual:
        return annualPrice;
    }
  }
}
