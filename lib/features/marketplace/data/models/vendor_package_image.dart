/// Mirrors eventsrus-backend's {@code VendorPackageImageResponse} field-for-field.
/// Real photos attached to one vendor package - shown in that package's own
/// edit view, and combined across every package as the storefront's Gallery
/// (see backend VendorPackageImageController's own doc comment).
class VendorPackageImage {
  final int id;
  final String imageUrl;
  final String? caption;
  final DateTime? createdAt;
  final List<String> tags;

  const VendorPackageImage({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.createdAt,
    this.tags = const [],
  });

  factory VendorPackageImage.fromJson(Map<String, dynamic> json) => VendorPackageImage(
        id: json['id'] as int,
        imageUrl: json['imageUrl'] as String,
        caption: json['caption'] as String?,
        createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );
}
