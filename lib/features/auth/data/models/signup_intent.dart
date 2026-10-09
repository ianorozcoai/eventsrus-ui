/// Which door a Google account first walked through - set once, at account
/// creation, and never changed afterward. Distinct from [Role], which still
/// freely flows planner -> vendor the moment a vendor finishes onboarding:
/// this is what lets AuthGate route a user who is mid-vendor-onboarding
/// (role still planner, signupIntent already vendor) back to finish it,
/// instead of treating "not yet vendor role" as "must be a real planner".
/// Mirrors eventsrus-backend's SignupIntent enum.
enum SignupIntent { planner, vendor }

extension SignupIntentApi on SignupIntent {
  String toApi() {
    switch (this) {
      case SignupIntent.planner:
        return 'PLANNER';
      case SignupIntent.vendor:
        return 'VENDOR';
    }
  }

  static SignupIntent fromApi(String value) {
    switch (value) {
      case 'PLANNER':
        return SignupIntent.planner;
      case 'VENDOR':
        return SignupIntent.vendor;
      default:
        throw FormatException('Unknown signup intent: $value');
    }
  }

  static SignupIntent? fromApiNullable(String? value) =>
      value == null ? null : fromApi(value);
}
