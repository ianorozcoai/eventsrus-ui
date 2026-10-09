import 'package:eventsrus_ui/features/subscription/data/models/billing_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every BillingCycle round-trips through toApi/fromApi', () {
    for (final cycle in BillingCycle.values) {
      expect(BillingCycleApi.fromApi(cycle.toApi()), cycle);
    }
  });

  test('toApi maps to the exact backend enum constants', () {
    expect(BillingCycle.monthly.toApi(), 'MONTHLY');
    expect(BillingCycle.quarterly.toApi(), 'QUARTERLY');
    expect(BillingCycle.semiAnnual.toApi(), 'SEMI_ANNUAL');
    expect(BillingCycle.annual.toApi(), 'ANNUAL');
  });

  test('fromApi throws on an unknown value', () {
    expect(() => BillingCycleApi.fromApi('WEEKLY'), throwsFormatException);
  });

  test('only semiAnnual and annual carry a savings badge', () {
    expect(BillingCycle.monthly.savingsBadge, isNull);
    expect(BillingCycle.quarterly.savingsBadge, isNull);
    expect(BillingCycle.semiAnnual.savingsBadge, 'Free 1 Month');
    expect(BillingCycle.annual.savingsBadge, 'Free 2 Months');
  });
}
