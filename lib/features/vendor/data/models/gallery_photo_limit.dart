/// Mirrors eventsrus-backend's {@code GalleryPhotoLimitResponse} - the
/// standalone-gallery photo cap (20 today) and how many of them this vendor
/// has used. See VendorGalleryPhotoController's `/limit` endpoint.
class GalleryPhotoLimit {
  final int limit;
  final int used;

  const GalleryPhotoLimit({required this.limit, required this.used});

  bool get isReached => used >= limit;

  factory GalleryPhotoLimit.fromJson(Map<String, dynamic> json) => GalleryPhotoLimit(
        limit: json['limit'] as int,
        used: json['used'] as int,
      );
}
