import 'package:eventsrus_ui/features/marketplace/data/models/vendor_public_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorPublicProfile.fromJson parses reviews and rating aggregate', () {
    final profile = VendorPublicProfile.fromJson({
      'vendorUserId': 10,
      'businessName': 'Dream Events Catering',
      'packages': [],
      'reviews': [
        {
          'id': 1,
          'rating': 4,
          'comment': 'Great food!',
          'createdAt': '2026-09-01T10:00:00Z',
          'updatedAt': '2026-09-01T10:00:00Z',
          'hidden': false,
          'reviewerName': 'Ana Reyes',
          'eventName': 'Birthday Party',
          'eventDate': '2026-08-15',
        },
      ],
      'averageRating': 4.5,
      'reviewCount': 2,
    });

    expect(profile.reviews, hasLength(1));
    expect(profile.reviews.single.rating, 4);
    expect(profile.reviews.single.reviewerName, 'Ana Reyes');
    expect(profile.averageRating, 4.5);
    expect(profile.reviewCount, 2);
  });

  test('VendorPublicProfile.fromJson defaults review fields when absent', () {
    final profile = VendorPublicProfile.fromJson({
      'vendorUserId': 10,
      'packages': [],
    });

    expect(profile.reviews, isEmpty);
    expect(profile.averageRating, isNull);
    expect(profile.reviewCount, 0);
  });
}
