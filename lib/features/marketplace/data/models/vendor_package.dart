import 'vendor_package_image.dart';

enum PackageType { service, product }

extension PackageTypeApi on PackageType {
  String toApi() => this == PackageType.service ? 'SERVICE' : 'PRODUCT';

  static PackageType fromApi(String value) => value == 'PRODUCT' ? PackageType.product : PackageType.service;

  String get label => this == PackageType.service ? 'Service' : 'Product';
}

/// How a package's price is displayed on the storefront - mirrors backend's
/// `PackagePricingType` enum exactly (FIXED/RANGE/QUOTE).
enum PackagePricingType { fixed, range, quote }

extension PackagePricingTypeApi on PackagePricingType {
  String toApi() => switch (this) {
        PackagePricingType.fixed => 'FIXED',
        PackagePricingType.range => 'RANGE',
        PackagePricingType.quote => 'QUOTE',
      };

  static PackagePricingType fromApi(String? value) => switch (value) {
        'RANGE' => PackagePricingType.range,
        'QUOTE' => PackagePricingType.quote,
        _ => PackagePricingType.fixed,
      };

  String get label => switch (this) {
        PackagePricingType.fixed => 'Fixed Price',
        PackagePricingType.range => 'Price Range',
        PackagePricingType.quote => 'Request for Quotation',
      };
}

/// Mirrors eventsrus-backend's {@code VendorPackageResponse} field-for-field.
class VendorPackage {
  final int id;
  final String name;
  final String? description;
  final PackageType packageType;
  final PackagePricingType pricingType;

  /// Used when [pricingType] == [PackagePricingType.fixed].
  final double? price;

  /// Used when [pricingType] == [PackagePricingType.range].
  final double? minPrice;
  final double? maxPrice;

  final bool active;

  /// Real photos attached to this package - see VendorPackageImageController.
  final List<VendorPackageImage> images;

  /// Vendor-defined group NAMES this package belongs to (not ids - the
  /// backend returns names here, same shape as the storefront filter tabs).
  /// A package can belong to any number of groups. See
  /// VendorPackageGroupService#setPackageGroups for assigning by id.
  final List<String> groups;

  const VendorPackage({
    required this.id,
    required this.name,
    this.description,
    this.price,
    required this.packageType,
    this.pricingType = PackagePricingType.fixed,
    this.minPrice,
    this.maxPrice,
    required this.active,
    this.images = const [],
    this.groups = const [],
  });

  factory VendorPackage.fromJson(Map<String, dynamic> json) => VendorPackage(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        packageType: PackageTypeApi.fromApi(json['packageType'] as String),
        pricingType: PackagePricingTypeApi.fromApi(json['pricingType'] as String?),
        minPrice: (json['minPrice'] as num?)?.toDouble(),
        maxPrice: (json['maxPrice'] as num?)?.toDouble(),
        active: json['active'] as bool,
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => VendorPackageImage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        groups: (json['groups'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );
}
