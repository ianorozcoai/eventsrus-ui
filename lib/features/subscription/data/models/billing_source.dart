/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.BillingSource}.
enum BillingSource { freeGrant, paypal, gcash, googlePlay, appStore }

extension BillingSourceApi on BillingSource {
  String toApi() {
    switch (this) {
      case BillingSource.freeGrant:
        return 'FREE_GRANT';
      case BillingSource.paypal:
        return 'PAYPAL';
      case BillingSource.gcash:
        return 'GCASH';
      case BillingSource.googlePlay:
        return 'GOOGLE_PLAY';
      case BillingSource.appStore:
        return 'APP_STORE';
    }
  }

  String get label {
    switch (this) {
      case BillingSource.freeGrant:
        return 'Free Grant';
      case BillingSource.paypal:
        return 'PayPal';
      case BillingSource.gcash:
        return 'GCash';
      case BillingSource.googlePlay:
        return 'Google Play';
      case BillingSource.appStore:
        return 'App Store';
    }
  }

  static BillingSource fromApi(String value) {
    switch (value) {
      case 'FREE_GRANT':
        return BillingSource.freeGrant;
      case 'PAYPAL':
        return BillingSource.paypal;
      case 'GCASH':
        return BillingSource.gcash;
      case 'GOOGLE_PLAY':
        return BillingSource.googlePlay;
      case 'APP_STORE':
        return BillingSource.appStore;
      default:
        throw FormatException('Unknown billing source: $value');
    }
  }

  static BillingSource? fromApiNullable(String? value) =>
      value == null ? null : fromApi(value);
}
