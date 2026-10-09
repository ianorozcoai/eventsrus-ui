import 'package:eventsrus_ui/features/vendor/data/models/vendor_event_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every VendorEventType round-trips through toApi/fromApi', () {
    for (final type in VendorEventType.values) {
      expect(VendorEventTypeApi.fromApi(type.toApi()), type);
    }
  });

  test('fromApi falls back to other for an unrecognized value', () {
    expect(VendorEventTypeApi.fromApi('SOMETHING_NEW'), VendorEventType.other);
  });
}
