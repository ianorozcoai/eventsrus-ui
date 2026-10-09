import 'package:eventsrus_ui/features/subscription/data/models/billing_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every BillingSource round-trips through toApi/fromApi', () {
    for (final source in BillingSource.values) {
      expect(BillingSourceApi.fromApi(source.toApi()), source);
    }
  });

  test('toApi maps to the exact backend enum constants', () {
    expect(BillingSource.freeGrant.toApi(), 'FREE_GRANT');
    expect(BillingSource.paypal.toApi(), 'PAYPAL');
    expect(BillingSource.gcash.toApi(), 'GCASH');
  });

  test('fromApiNullable passes through null and parses otherwise', () {
    expect(BillingSourceApi.fromApiNullable(null), isNull);
    expect(BillingSourceApi.fromApiNullable('GCASH'), BillingSource.gcash);
  });

  test('fromApi throws on an unknown value', () {
    expect(() => BillingSourceApi.fromApi('CRYPTO'), throwsFormatException);
  });
}
