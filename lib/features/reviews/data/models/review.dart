/// Mirrors eventsrus-backend's {@code ReviewResponse} field-for-field.
///
/// A planner's review of one completed booking (see ReviewController /
/// ReviewService). `hidden` reviews are never returned to a planner or
/// vendor by the backend (ReviewService#listPublic filters them out before
/// they ever reach VendorPublicProfileResponse), so in practice every
/// `Review` this app sees already has `hidden == false` - the field is kept
/// here purely because it's part of the DTO shape.
class Review {
  final int id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hidden;

  // Context shown alongside the review on the storefront / admin view.
  final String? reviewerName;
  final String? eventName;
  final DateTime? eventDate;

  const Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.hidden = false,
    this.reviewerName,
    this.eventName,
    this.eventDate,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        rating: json['rating'] as int,
        comment: json['comment'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        hidden: json['hidden'] as bool? ?? false,
        reviewerName: json['reviewerName'] as String?,
        eventName: json['eventName'] as String?,
        eventDate: json['eventDate'] == null ? null : DateTime.parse(json['eventDate'] as String),
      );
}
