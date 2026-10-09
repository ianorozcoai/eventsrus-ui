/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.BillingCycle}.
/// All four cycles are real, working options on the backend (and on the web
/// reference app's billing-cycle picker) - monthly is just hidden on web's UI
/// while still being fully functional, so it stays available here too.
enum BillingCycle { monthly, quarterly, semiAnnual, annual }

extension BillingCycleApi on BillingCycle {
  String toApi() {
    switch (this) {
      case BillingCycle.monthly:
        return 'MONTHLY';
      case BillingCycle.quarterly:
        return 'QUARTERLY';
      case BillingCycle.semiAnnual:
        return 'SEMI_ANNUAL';
      case BillingCycle.annual:
        return 'ANNUAL';
    }
  }

  /// Short label for the billing-cycle picker, mirroring the web app's
  /// proPlanPickerForm fragment copy.
  String get label {
    switch (this) {
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.semiAnnual:
        return 'Semi-Annual';
      case BillingCycle.annual:
        return 'Annual';
    }
  }

  /// Parenthetical duration shown next to the label, e.g. "(3 mo.)".
  String get durationLabel {
    switch (this) {
      case BillingCycle.monthly:
        return '1 month';
      case BillingCycle.quarterly:
        return '3 mo.';
      case BillingCycle.semiAnnual:
        return '6 mo.';
      case BillingCycle.annual:
        return '12 mo.';
    }
  }

  /// "Free N Month(s)" savings badge, or null for cycles with no discount -
  /// matches the web app's badges exactly.
  String? get savingsBadge {
    switch (this) {
      case BillingCycle.monthly:
      case BillingCycle.quarterly:
        return null;
      case BillingCycle.semiAnnual:
        return 'Free 1 Month';
      case BillingCycle.annual:
        return 'Free 2 Months';
    }
  }

  static BillingCycle fromApi(String value) {
    switch (value) {
      case 'MONTHLY':
        return BillingCycle.monthly;
      case 'QUARTERLY':
        return BillingCycle.quarterly;
      case 'SEMI_ANNUAL':
        return BillingCycle.semiAnnual;
      case 'ANNUAL':
        return BillingCycle.annual;
      default:
        throw FormatException('Unknown billing cycle: $value');
    }
  }
}
