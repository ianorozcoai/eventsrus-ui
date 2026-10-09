import '../../../reviews/data/models/review.dart';
import '../../../vendor/data/models/vendor_payment_method.dart';
import '../../../vendor/data/models/vendor_social_media_link.dart';
import 'vendor_legal_document.dart';
import 'vendor_package.dart';
import 'vendor_package_image.dart';

/// Mirrors eventsrus-backend's VendorPublicProfileResponse field-for-field -
/// what a planner sees as this vendor's storefront, also reused read-only
/// as the vendor's own "My Page" preview (VendorStorefrontScreen). Note:
/// eventsrus-web's own view-model additionally carries tierLabel/
/// primaryRegion/responseTime/bookingsCount hero-banner fields, but those
/// are stubs on the web side only (no backend support exists for them yet -
/// see that class's own doc comment) - deliberately not mirrored here since
/// this app talks to the real backend response directly, which has no such
/// fields to parse.
class VendorPublicProfile {
  final int vendorUserId;
  final String? businessName;
  final String? ownerName;
  final String? description;
  final String? logoImageUrl;
  final String? businessType;
  final String? city;
  final String? state;
  final String? country;
  final String? contactEmail;
  final String? phoneNumber;
  final List<VendorPackage> packages;

  // Real, admin-reviewed verification (not just "has uploaded an ID card
  // and selfie") - see AdminVendorController for the review workflow.
  final bool identityVerified;

  // Business-registration paperwork (DTI, SEC, ...) - safe to show
  // directly, unlike the personal ID documents behind identityVerified.
  final List<VendorLegalDocument> legalDocuments;

  // Every photo across every package this vendor has, combined - distinct
  // from an individual package's own packages[].images.
  final List<VendorPackageImage> galleryImages;

  // Every tag/group name the vendor has CREATED, not just ones currently
  // applied to a photo/package - an empty one still gets its own filter,
  // same convention as eventsrus-web's storefront tabs.
  final List<String> availableImageTags;
  final List<String> availableGroups;

  final List<VendorSocialMediaLink> socialMediaLinks;

  final String? paymentInstructions;
  // Only ever APPROVED entries - see VendorDirectoryService.
  final List<VendorPaymentMethod> paymentMethods;

  // Real planner reviews (hidden ones already excluded by the backend),
  // newest first, plus the aggregate - see ReviewController/ReviewService.
  // averageRating is null when there are no reviews yet.
  final List<Review> reviews;
  final double? averageRating;
  final int reviewCount;

  const VendorPublicProfile({
    required this.vendorUserId,
    this.businessName,
    this.ownerName,
    this.description,
    this.logoImageUrl,
    this.businessType,
    this.city,
    this.state,
    this.country,
    this.contactEmail,
    this.phoneNumber,
    required this.packages,
    this.identityVerified = false,
    this.legalDocuments = const [],
    this.galleryImages = const [],
    this.availableImageTags = const [],
    this.availableGroups = const [],
    this.socialMediaLinks = const [],
    this.paymentInstructions,
    this.paymentMethods = const [],
    this.reviews = const [],
    this.averageRating,
    this.reviewCount = 0,
  });

  factory VendorPublicProfile.fromJson(Map<String, dynamic> json) => VendorPublicProfile(
        vendorUserId: json['vendorUserId'] as int,
        businessName: json['businessName'] as String?,
        ownerName: json['ownerName'] as String?,
        description: json['description'] as String?,
        logoImageUrl: json['logoImageUrl'] as String?,
        businessType: json['businessType'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        country: json['country'] as String?,
        contactEmail: json['contactEmail'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        packages: (json['packages'] as List? ?? [])
            .map((e) => VendorPackage.fromJson(e as Map<String, dynamic>))
            .toList(),
        identityVerified: json['identityVerified'] as bool? ?? false,
        legalDocuments: (json['legalDocuments'] as List? ?? [])
            .map((e) => VendorLegalDocument.fromJson(e as Map<String, dynamic>))
            .toList(),
        galleryImages: (json['galleryImages'] as List? ?? [])
            .map((e) => VendorPackageImage.fromJson(e as Map<String, dynamic>))
            .toList(),
        availableImageTags: (json['availableImageTags'] as List? ?? []).map((e) => e as String).toList(),
        availableGroups: (json['availableGroups'] as List? ?? []).map((e) => e as String).toList(),
        socialMediaLinks: (json['socialMediaLinks'] as List? ?? [])
            .map((e) => VendorSocialMediaLink.fromJson(e as Map<String, dynamic>))
            .toList(),
        paymentInstructions: json['paymentInstructions'] as String?,
        paymentMethods: (json['paymentMethods'] as List? ?? [])
            .map((e) => VendorPaymentMethod.fromJson(e as Map<String, dynamic>))
            .toList(),
        reviews: (json['reviews'] as List? ?? []).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList(),
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        reviewCount: json['reviewCount'] as int? ?? 0,
      );
}
