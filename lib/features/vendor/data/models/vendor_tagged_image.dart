import 'image_source.dart';
import 'vendor_image_tag.dart';

/// Mirrors eventsrus-backend's {@code VendorTaggedImageResponse} - the
/// vendor-facing "every image I have" shape (standalone gallery photos and
/// every package's own photos, combined), distinct from the public
/// storefront shape (VendorPackageImage) in that it knows which underlying
/// row to edit (source + packageId) and carries the package name for
/// context - see VendorImageTagService#listAllTaggableImages.
class VendorTaggedImage {
  final int id;
  final String imageUrl;
  final String? caption;
  final ImageSource source;

  /// Only non-null when [source] == [ImageSource.package].
  final int? packageId;
  final String? packageName;

  final List<VendorImageTag> tags;

  const VendorTaggedImage({
    required this.id,
    required this.imageUrl,
    this.caption,
    required this.source,
    this.packageId,
    this.packageName,
    this.tags = const [],
  });

  factory VendorTaggedImage.fromJson(Map<String, dynamic> json) => VendorTaggedImage(
        id: json['id'] as int,
        imageUrl: json['imageUrl'] as String,
        caption: json['caption'] as String?,
        source: ImageSourceApi.fromApi(json['source'] as String),
        packageId: json['packageId'] as int?,
        packageName: json['packageName'] as String?,
        tags: (json['tags'] as List? ?? []).map((e) => VendorImageTag.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
