import '../../../auth/data/models/business_type.dart';

/// One category offered during pre-creation category selection. [type] is
/// the raw BusinessType enum value as the backend sends it (e.g. "VENUE"),
/// used as-is for selection/API calls; [label] is derived client-side via
/// BusinessTypeApi.labelOrRaw for display.
class RecommendationCategory {
  final String type;
  final String label;

  const RecommendationCategory({required this.type, required this.label});

  factory RecommendationCategory.fromRaw(String type) =>
      RecommendationCategory(type: type, label: BusinessTypeApi.labelOrRaw(type));
}

/// Essential/optional category split for one event type - mirrors the
/// backend's RecommendationController#CategoryRecommendationResponse,
/// fetched before the event itself exists (see EventApi#getRecommendations).
/// That DTO is a record of two `Set<BusinessType>`, which Jackson serializes
/// as flat arrays of plain enum strings (e.g. ["VENUE","CATERING"]) - NOT
/// {type,label} objects, despite how this used to be parsed here. That
/// mismatch threw a silent TypeError on every element, caught by the
/// screen's generic catch block and surfaced as "Could not load supplier
/// categories" with nothing in the backend logs (the HTTP call itself
/// succeeded) - this was the real cause of step 1 never reaching step 2.
class EventRecommendations {
  final List<RecommendationCategory> essential;
  final List<RecommendationCategory> optional;

  const EventRecommendations({required this.essential, required this.optional});

  factory EventRecommendations.fromJson(Map<String, dynamic> json) => EventRecommendations(
        essential: (json['essential'] as List? ?? [])
            .map((e) => RecommendationCategory.fromRaw(e as String))
            .toList(),
        optional: (json['optional'] as List? ?? [])
            .map((e) => RecommendationCategory.fromRaw(e as String))
            .toList(),
      );
}
