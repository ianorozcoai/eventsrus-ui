import 'package:eventsrus_ui/features/planner/data/models/event_recommendations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EventRecommendations.fromJson parses the real backend shape: flat BusinessType string arrays', () {
    // Regression test: the backend's CategoryRecommendationResponse is a
    // record of two Set<BusinessType>, which Jackson serializes as flat
    // arrays of raw enum strings - NOT {type,label} objects. This model
    // used to assume the latter and crashed with a TypeError on every
    // single call, silently caught by the screen's generic catch block and
    // surfaced only as "Could not load supplier categories" with nothing
    // in the backend logs, since the HTTP call itself succeeded.
    final recommendations = EventRecommendations.fromJson({
      'essential': ['VENUE', 'CATERING'],
      'optional': ['PHOTO_AND_VIDEO'],
    });

    expect(recommendations.essential, hasLength(2));
    expect(recommendations.essential.map((c) => c.type), ['VENUE', 'CATERING']);
    expect(recommendations.essential.map((c) => c.label), ['Venue', 'Catering']);
    expect(recommendations.optional, hasLength(1));
    expect(recommendations.optional.single.type, 'PHOTO_AND_VIDEO');
    expect(recommendations.optional.single.label, 'Photo and Video');
  });

  test('EventRecommendations.fromJson falls back to the raw string for an unrecognized BusinessType', () {
    final recommendations = EventRecommendations.fromJson({
      'essential': ['SOME_FUTURE_TYPE_NOT_YET_ADDED'],
      'optional': [],
    });

    expect(recommendations.essential.single.type, 'SOME_FUTURE_TYPE_NOT_YET_ADDED');
    expect(recommendations.essential.single.label, 'SOME_FUTURE_TYPE_NOT_YET_ADDED');
  });

  test('EventRecommendations.fromJson handles missing essential/optional keys', () {
    final recommendations = EventRecommendations.fromJson({});

    expect(recommendations.essential, isEmpty);
    expect(recommendations.optional, isEmpty);
  });
}
