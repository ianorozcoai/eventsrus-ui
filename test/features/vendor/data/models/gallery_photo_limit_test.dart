import 'package:eventsrus_ui/features/vendor/data/models/gallery_photo_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GalleryPhotoLimit.fromJson parses limit and used', () {
    final limit = GalleryPhotoLimit.fromJson({'limit': 20, 'used': 5});

    expect(limit.limit, 20);
    expect(limit.used, 5);
    expect(limit.isReached, isFalse);
  });

  test('isReached is true once used reaches the limit', () {
    final limit = GalleryPhotoLimit.fromJson({'limit': 20, 'used': 20});
    expect(limit.isReached, isTrue);
  });
}
