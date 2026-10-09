/// Mirrors eventsrus-backend's {@code VendorImageTagResponse} - a
/// vendor-created label applicable to any of their images (standalone
/// gallery photos today; see VendorImageTagController/VendorImageTagService).
class VendorImageTag {
  final int id;
  final String name;

  const VendorImageTag({required this.id, required this.name});

  factory VendorImageTag.fromJson(Map<String, dynamic> json) => VendorImageTag(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
