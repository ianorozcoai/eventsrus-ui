/// One result row from a deliberate name search (VendorDirectoryApi.search)
/// - mirrors eventsrus-backend's SuggestedVendorResponse, minus vendorType
/// (a vendor can have several, and search results aren't grouped by
/// category the way event.suggestions are). businessTypes carries the full
/// list instead, shown in place of a Verified/Top Supplier badge - most
/// vendors in this marketplace aren't registered businesses and never
/// clear verification, so those badges read as friction rather than signal
/// in an ungrouped, marketplace-wide search like this one.
class VendorSearchResult {
  final int vendorProfileId;
  final String businessName;
  final String slug;
  final String? logoImageUrl;
  final String? city;
  final bool verified;
  final bool topVendor;
  final double? averageRating;
  final int reviewCount;
  final List<String> businessTypes;

  const VendorSearchResult({
    required this.vendorProfileId,
    required this.businessName,
    required this.slug,
    this.logoImageUrl,
    this.city,
    this.verified = false,
    this.topVendor = false,
    this.averageRating,
    this.reviewCount = 0,
    this.businessTypes = const [],
  });

  factory VendorSearchResult.fromJson(Map<String, dynamic> json) =>
      VendorSearchResult(
        vendorProfileId: json['vendorProfileId'] as int,
        businessName: json['businessName'] as String? ?? 'Vendor',
        slug: json['slug'] as String,
        logoImageUrl: json['logoImageUrl'] as String?,
        city: json['city'] as String?,
        verified: json['verified'] as bool? ?? false,
        topVendor: json['topVendor'] as bool? ?? false,
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        reviewCount: json['reviewCount'] as int? ?? 0,
        businessTypes: (json['businessTypes'] as List? ?? []).map((e) => e as String).toList(),
      );
}
