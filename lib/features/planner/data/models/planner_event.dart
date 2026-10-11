import 'planner_event_type.dart';

class SuggestedVendor {
  final String vendorType;
  // Same value repeated on every row sharing a vendorType - selecting a
  // category to actively browse/pursue, and its optional budget earmark,
  // are per-category choices, not per-vendor ones (see backend's
  // SuggestedVendorResponse javadoc).
  final bool categorySelected;
  final double? categoryBudget;
  // Whether this category is "essential" for the event's type (backend's
  // event-type matrix) vs. "Other Suppliers" - same value on every row
  // sharing a vendorType, same repetition note as categorySelected above.
  final bool essential;
  final int? vendorProfileId;
  final String? businessName;
  final String? slug;
  final String? logoImageUrl;
  final String? city;
  // The vendor's full business-type list (not just vendorType above, which
  // is the one category this row is matched under) - shown in the Browse
  // popup instead of a Verified/Top Supplier badge.
  final List<String> businessTypes;

  const SuggestedVendor({
    required this.vendorType,
    this.categorySelected = false,
    this.categoryBudget,
    this.essential = false,
    this.vendorProfileId,
    this.businessName,
    this.slug,
    this.logoImageUrl,
    this.city,
    this.businessTypes = const [],
  });

  bool get isRealVendor => vendorProfileId != null && slug != null;

  factory SuggestedVendor.fromJson(Map<String, dynamic> json) => SuggestedVendor(
        vendorType: json['vendorType'] as String,
        categorySelected: json['categorySelected'] as bool? ?? false,
        categoryBudget: (json['categoryBudget'] as num?)?.toDouble(),
        essential: json['essential'] as bool? ?? false,
        vendorProfileId: json['vendorProfileId'] as int?,
        businessName: json['businessName'] as String?,
        slug: json['slug'] as String?,
        logoImageUrl: json['logoImageUrl'] as String?,
        city: json['city'] as String?,
        businessTypes: (json['businessTypes'] as List? ?? []).map((e) => e as String).toList(),
      );
}

enum ChecklistItemStatus { todo, done, dismissed }

extension ChecklistItemStatusApi on ChecklistItemStatus {
  String toApi() => switch (this) {
        ChecklistItemStatus.todo => 'TODO',
        ChecklistItemStatus.done => 'DONE',
        ChecklistItemStatus.dismissed => 'DISMISSED',
      };
}

class EventChecklistItem {
  final int id;
  final String label;
  final ChecklistItemStatus status;
  final String source;
  // Non-null only for a "Book a X vendor" item created by checking a
  // supplier category.
  final String? vendorType;
  // Non-null only for a "Follow up with X" item created by bookmarking a
  // specific vendor on their storefront - lets the UI link straight there.
  final int? vendorProfileId;
  final String? vendorSlug;

  const EventChecklistItem({
    required this.id,
    required this.label,
    required this.status,
    required this.source,
    this.vendorType,
    this.vendorProfileId,
    this.vendorSlug,
  });

  factory EventChecklistItem.fromJson(Map<String, dynamic> json) => EventChecklistItem(
        id: json['id'] as int,
        label: json['label'] as String,
        status: switch (json['status'] as String?) {
          'DONE' => ChecklistItemStatus.done,
          'DISMISSED' => ChecklistItemStatus.dismissed,
          _ => ChecklistItemStatus.todo,
        },
        source: json['source'] as String,
        vendorType: json['vendorType'] as String?,
        vendorProfileId: json['vendorProfileId'] as int?,
        vendorSlug: json['vendorSlug'] as String?,
      );
}

class PlannerEvent {
  final int id;
  final String? name;
  final PlannerEventType eventType;
  final DateTime? eventDate;
  final String? location;
  final String? description;
  final double? budget;
  final int? guestCount;
  final String? aiIdeaText;
  final bool saved;
  final List<SuggestedVendor> suggestions;
  final List<EventChecklistItem> checklist;
  final List<int> bookmarkedVendorProfileIds;

  const PlannerEvent({
    required this.id,
    this.name,
    required this.eventType,
    this.eventDate,
    this.location,
    this.description,
    this.budget,
    this.guestCount,
    this.aiIdeaText,
    required this.saved,
    required this.suggestions,
    required this.checklist,
    this.bookmarkedVendorProfileIds = const [],
  });

  factory PlannerEvent.fromJson(Map<String, dynamic> json) => PlannerEvent(
        id: json['id'] as int,
        name: json['name'] as String?,
        eventType: PlannerEventTypeApi.fromApi(json['eventType'] as String),
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        location: json['location'] as String?,
        description: json['description'] as String?,
        budget: (json['budget'] as num?)?.toDouble(),
        guestCount: json['guestCount'] as int?,
        aiIdeaText: json['aiIdeaText'] as String?,
        saved: json['saved'] as bool,
        suggestions: (json['suggestions'] as List? ?? [])
            .map((e) => SuggestedVendor.fromJson(e as Map<String, dynamic>))
            .toList(),
        checklist: (json['checklist'] as List? ?? [])
            .map((e) => EventChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        bookmarkedVendorProfileIds:
            (json['bookmarkedVendorProfileIds'] as List? ?? []).map((e) => e as int).toList(),
      );
}

class PlannerEventSummary {
  final int id;
  final String? name;
  final PlannerEventType eventType;
  final DateTime? eventDate;
  final bool saved;

  const PlannerEventSummary({
    required this.id,
    this.name,
    required this.eventType,
    this.eventDate,
    required this.saved,
  });

  factory PlannerEventSummary.fromJson(Map<String, dynamic> json) => PlannerEventSummary(
        id: json['id'] as int,
        name: json['name'] as String?,
        eventType: PlannerEventTypeApi.fromApi(json['eventType'] as String),
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        saved: json['saved'] as bool,
      );
}
