import 'package:eventsrus_ui/features/vendor/data/models/vendor_event_type.dart';
import 'package:eventsrus_ui/features/vendor/data/models/vendor_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorSettings.fromJson parses Service Scope fields', () {
    final settings = VendorSettings.fromJson({
      'slug': 'acme-catering',
      'businessName': 'Acme Catering',
      'maxGuestCapacity': 200,
      'maxCustomersPerDay': 3,
      'basePrice': 50000.0,
      'leadTimeDays': 14,
      'storefrontOverview': 'Full service catering.',
      'operatingAreas': ['Metro Manila', 'Cavite'],
      'cateredEventTypes': ['WEDDING', 'CORPORATE_EVENT'],
    });

    expect(settings.slug, 'acme-catering');
    expect(settings.maxCustomersPerDay, 3);
    expect(settings.operatingAreas, ['Metro Manila', 'Cavite']);
    expect(settings.cateredEventTypes, [VendorEventType.wedding, VendorEventType.corporateEvent]);
  });

  test('VendorSettings.fromJson defaults operatingAreas/cateredEventTypes to empty when absent', () {
    final settings = VendorSettings.fromJson({'businessName': 'Acme Catering'});

    expect(settings.operatingAreas, isEmpty);
    expect(settings.cateredEventTypes, isEmpty);
  });

  test('toJson round-trips Service Scope fields', () {
    const settings = VendorSettings(
      businessName: 'Acme Catering',
      maxCustomersPerDay: 3,
      operatingAreas: ['Metro Manila'],
      cateredEventTypes: [VendorEventType.wedding],
    );

    final json = settings.toJson();

    expect(json['maxCustomersPerDay'], 3);
    expect(json['operatingAreas'], ['Metro Manila']);
    expect(json['cateredEventTypes'], ['WEDDING']);
  });

  test('copyWith preserves slug and updates Service Scope fields', () {
    const settings = VendorSettings(slug: 'acme-catering', maxCustomersPerDay: 3);
    final updated = settings.copyWith(maxCustomersPerDay: 5, operatingAreas: ['Cavite']);

    expect(updated.slug, 'acme-catering');
    expect(updated.maxCustomersPerDay, 5);
    expect(updated.operatingAreas, ['Cavite']);
  });

  test('paymentInstructions round-trips through fromJson/toJson and copyWith preserves other fields', () {
    final settings = VendorSettings.fromJson({
      'businessName': 'Acme Catering',
      'paymentInstructions': 'GCash preferred for the down payment.',
    });

    expect(settings.paymentInstructions, 'GCash preferred for the down payment.');
    expect(settings.toJson()['paymentInstructions'], 'GCash preferred for the down payment.');

    final updated = settings.copyWith(paymentInstructions: 'Bank transfer only.');
    expect(updated.paymentInstructions, 'Bank transfer only.');
    expect(updated.businessName, 'Acme Catering');
  });
}
