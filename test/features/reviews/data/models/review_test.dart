import 'package:eventsrus_ui/features/reviews/data/models/review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Review.fromJson parses a full response', () {
    final review = Review.fromJson({
      'id': 42,
      'rating': 5,
      'comment': 'Fantastic service, highly recommend!',
      'createdAt': '2026-09-01T10:00:00Z',
      'updatedAt': '2026-09-02T10:00:00Z',
      'hidden': false,
      'reviewerName': 'Ian Orozco',
      'eventName': 'Wedding Reception',
      'eventDate': '2026-08-20',
    });

    expect(review.id, 42);
    expect(review.rating, 5);
    expect(review.comment, 'Fantastic service, highly recommend!');
    expect(review.createdAt, DateTime.parse('2026-09-01T10:00:00Z'));
    expect(review.updatedAt, DateTime.parse('2026-09-02T10:00:00Z'));
    expect(review.hidden, false);
    expect(review.reviewerName, 'Ian Orozco');
    expect(review.eventName, 'Wedding Reception');
    expect(review.eventDate, DateTime.parse('2026-08-20'));
  });

  test('Review.fromJson defaults hidden to false and tolerates null context fields', () {
    final review = Review.fromJson({
      'id': 1,
      'rating': 3,
      'comment': 'Okay experience.',
      'createdAt': '2026-09-01T10:00:00Z',
      'updatedAt': '2026-09-01T10:00:00Z',
      'reviewerName': null,
      'eventName': null,
      'eventDate': null,
    });

    expect(review.hidden, false);
    expect(review.reviewerName, isNull);
    expect(review.eventName, isNull);
    expect(review.eventDate, isNull);
  });
}
