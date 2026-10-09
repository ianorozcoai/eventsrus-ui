import 'package:eventsrus_ui/features/marketplace/data/models/vendor_package_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorPackageGroup.fromJson parses id and name', () {
    final group = VendorPackageGroup.fromJson({'id': 9, 'name': 'Weddings'});

    expect(group.id, 9);
    expect(group.name, 'Weddings');
  });
}
