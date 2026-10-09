import 'package:eventsrus_ui/features/vendor/data/models/vendor_image_tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorImageTag.fromJson parses id and name', () {
    final tag = VendorImageTag.fromJson({'id': 7, 'name': 'Weddings'});

    expect(tag.id, 7);
    expect(tag.name, 'Weddings');
  });
}
