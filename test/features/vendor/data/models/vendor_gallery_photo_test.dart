import 'package:eventsrus_ui/features/vendor/data/models/vendor_gallery_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorGalleryPhoto.fromJson parses a full response', () {
    final photo = VendorGalleryPhoto.fromJson({
      'id': 1,
      'imageUrl': 'https://example.com/photo.jpg',
      'caption': 'Our setup',
      'createdAt': '2026-01-01T00:00:00Z',
      'tags': ['Weddings', 'Outdoor'],
    });

    expect(photo.id, 1);
    expect(photo.imageUrl, 'https://example.com/photo.jpg');
    expect(photo.caption, 'Our setup');
    expect(photo.createdAt, isNotNull);
    expect(photo.tags, ['Weddings', 'Outdoor']);
  });

  test('VendorGalleryPhoto.fromJson defaults optional fields when absent', () {
    final photo = VendorGalleryPhoto.fromJson({
      'id': 2,
      'imageUrl': 'https://example.com/photo2.jpg',
    });

    expect(photo.caption, isNull);
    expect(photo.createdAt, isNull);
    expect(photo.tags, isEmpty);
  });
}
