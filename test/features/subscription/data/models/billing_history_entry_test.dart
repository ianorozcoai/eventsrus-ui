import 'package:eventsrus_ui/features/auth/data/models/plan_tier.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_history_entry.dart';
import 'package:eventsrus_ui/features/subscription/data/models/billing_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson parses a full PayPal entry', () {
    final entry = BillingHistoryEntry.fromJson({
      'id': 1,
      'plan': 'PRO',
      'billingSource': 'PAYPAL',
      'amount': 2997.0,
      'currency': 'PHP',
      'paypalTransactionId': 'TXN-123',
      'periodStart': '2026-01-01T00:00:00Z',
      'periodEnd': '2026-04-01T00:00:00Z',
      'occurredAt': '2026-01-01T00:05:00Z',
    });

    expect(entry.id, 1);
    expect(entry.plan, PlanTier.pro);
    expect(entry.billingSource, BillingSource.paypal);
    expect(entry.amount, 2997.0);
    expect(entry.currency, 'PHP');
    expect(entry.paypalTransactionId, 'TXN-123');
    expect(entry.periodStart, DateTime.parse('2026-01-01T00:00:00Z'));
    expect(entry.periodEnd, DateTime.parse('2026-04-01T00:00:00Z'));
    expect(entry.occurredAt, DateTime.parse('2026-01-01T00:05:00Z'));
  });

  test('fromJson parses a GCash entry with no PayPal transaction id', () {
    final entry = BillingHistoryEntry.fromJson({
      'id': 2,
      'plan': 'PRO',
      'billingSource': 'GCASH',
      'amount': 999.0,
      'currency': 'PHP',
      'paypalTransactionId': null,
      'periodStart': null,
      'periodEnd': null,
      'occurredAt': '2026-02-01T00:00:00Z',
    });

    expect(entry.billingSource, BillingSource.gcash);
    expect(entry.paypalTransactionId, isNull);
    expect(entry.periodStart, isNull);
    expect(entry.periodEnd, isNull);
  });

  test('fromJson converts an integer-valued amount to a double', () {
    final entry = BillingHistoryEntry.fromJson({
      'id': 3,
      'plan': 'PRO',
      'billingSource': 'FREE_GRANT',
      'amount': 0,
      'currency': 'PHP',
      'occurredAt': '2026-03-01T00:00:00Z',
    });

    expect(entry.amount, 0.0);
    expect(entry.billingSource, BillingSource.freeGrant);
  });
}
