/// Mirrors eventsrus-backend's {@code VendorPackageImageResponse} field-for-field
/// (the same response shape VendorGalleryPhotoController returns for its
/// standalone photos - see that controller's own doc comment). Kept as its
/// own class rather than reusing VendorPackageImage since the two live in
/// different features and are fetched/mutated through different endpoints.
class VendorGalleryPhoto {
  final int id;
  final String imageUrl;
  final String? caption;
  final DateTime? createdAt;
  final List<String> tags;

  const VendorGalleryPhoto({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.createdAt,
    this.tags = const [],
  });

  factory VendorGalleryPhoto.fromJson(Map<String, dynamic> json) => VendorGalleryPhoto(
        id: json['id'] as int,
        imageUrl: json['imageUrl'] as String,
        caption: json['caption'] as String?,
        createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );
}
