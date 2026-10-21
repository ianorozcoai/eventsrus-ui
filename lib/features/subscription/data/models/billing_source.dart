/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.BillingSource}.
enum BillingSource { freeGrant, paypal, gcash, googlePlay }

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
      default:
        throw FormatException('Unknown billing source: $value');
    }
  }

  static BillingSource? fromApiNullable(String? value) =>
      value == null ? null : fromApi(value);
}
