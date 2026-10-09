/// Mirrors eventsrus-backend's {@code VendorPackageGroupResponse}
/// field-for-field. A vendor-defined grouping (e.g. "Weddings", "Birthdays")
/// that can be attached to any number of that vendor's packages - surfaced
/// as storefront filter tabs (see backend VendorPackageGroupController).
class VendorPackageGroup {
  final int id;
  final String name;

  const VendorPackageGroup({required this.id, required this.name});

  factory VendorPackageGroup.fromJson(Map<String, dynamic> json) => VendorPackageGroup(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
