import 'planner_event_type.dart';

class SuggestedVendor {
  final String vendorType;
  final int? vendorProfileId;
  final String? businessName;
  final String? slug;
  final String? logoImageUrl;
  final String? city;

  const SuggestedVendor({
    required this.vendorType,
    this.vendorProfileId,
    this.businessName,
    this.slug,
    this.logoImageUrl,
    this.city,
  });

  bool get isRealVendor => vendorProfileId != null && slug != null;

  factory SuggestedVendor.fromJson(Map<String, dynamic> json) => SuggestedVendor(
        vendorType: json['vendorType'] as String,
        vendorProfileId: json['vendorProfileId'] as int?,
        businessName: json['businessName'] as String?,
        slug: json['slug'] as String?,
        logoImageUrl: json['logoImageUrl'] as String?,
        city: json['city'] as String?,
      );
}

enum ChecklistItemStatus { todo, done }

class EventChecklistItem {
  final int id;
  final String label;
  final ChecklistItemStatus status;
  final String source;

  const EventChecklistItem({
    required this.id,
    required this.label,
    required this.status,
    required this.source,
  });

  factory EventChecklistItem.fromJson(Map<String, dynamic> json) => EventChecklistItem(
        id: json['id'] as int,
        label: json['label'] as String,
        status: (json['status'] as String) == 'DONE' ? ChecklistItemStatus.done : ChecklistItemStatus.todo,
        source: json['source'] as String,
      );
}

class PlannerEvent {
  final int id;
  final String? name;
  final PlannerEventType eventType;
  final DateTime? eventDate;
  final String? location;
  final String? description;
  final String? aiIdeaText;
  final bool saved;
  final List<SuggestedVendor> suggestions;
  final List<EventChecklistItem> checklist;

  const PlannerEvent({
    required this.id,
    this.name,
    required this.eventType,
    this.eventDate,
    this.location,
    this.description,
    this.aiIdeaText,
    required this.saved,
    required this.suggestions,
    required this.checklist,
  });

  factory PlannerEvent.fromJson(Map<String, dynamic> json) => PlannerEvent(
        id: json['id'] as int,
        name: json['name'] as String?,
        eventType: PlannerEventTypeApi.fromApi(json['eventType'] as String),
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
        location: json['location'] as String?,
        description: json['description'] as String?,
        aiIdeaText: json['aiIdeaText'] as String?,
        saved: json['saved'] as bool,
        suggestions: (json['suggestions'] as List? ?? [])
            .map((e) => SuggestedVendor.fromJson(e as Map<String, dynamic>))
            .toList(),
        checklist: (json['checklist'] as List? ?? [])
            .map((e) => EventChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
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
