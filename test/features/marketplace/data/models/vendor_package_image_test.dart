import 'package:eventsrus_ui/features/marketplace/data/models/vendor_package_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorPackageImage.fromJson parses a full response', () {
    final image = VendorPackageImage.fromJson({
      'id': 5,
      'imageUrl': 'https://cdn.example.com/a.jpg',
      'caption': 'Venue setup',
      'createdAt': '2026-02-01T08:30:00Z',
      'tags': ['indoor', 'evening'],
    });

    expect(image.id, 5);
    expect(image.imageUrl, 'https://cdn.example.com/a.jpg');
    expect(image.caption, 'Venue setup');
    expect(image.createdAt, DateTime.parse('2026-02-01T08:30:00Z'));
    expect(image.tags, ['indoor', 'evening']);
  });

  test('VendorPackageImage.fromJson defaults optional fields when absent', () {
    final image = VendorPackageImage.fromJson({
      'id': 6,
      'imageUrl': 'https://cdn.example.com/b.jpg',
      'caption': null,
      'createdAt': null,
    });

    expect(image.caption, isNull);
    expect(image.createdAt, isNull);
    expect(image.tags, isEmpty);
  });
}
