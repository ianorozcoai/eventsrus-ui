import '../../../auth/data/models/business_type.dart';
import 'vendor_event_type.dart';

/// Mirrors eventsrus-backend's VendorSettingsResponse/VendorSettingsRequest
/// field-for-field. businessType/primaryCategory/retainerPercentage and
/// cancellationPolicy/refundTerms as plain text no longer exist on the
/// backend at all - businessTypes (a list) replaced the first, the backend
/// dropped retainer entirely, and the latter two are vendor-uploaded PDFs
/// now (cancellationPolicyUrl/refundTermsUrl, set via a separate multipart
/// file part on PUT .../settings, not a form field - see
/// VendorSettingsApi.updateSettings). storefrontOverview is kept read/write
/// for real-DTO parity even though no current UI edits it (superseded by
/// description), same as the real backend DTO itself.
class VendorSettings {
  // Needed to link to the vendor's own public storefront (GET
  // /api/v1/vendors/{slug}) - there's no other authenticated endpoint that
  // exposes it. Read-only: never sent back in toJson.
  final String? slug;
  final String? businessName;
  final String? description;
  final String? ownerName;
  final List<BusinessType> businessTypes;
  final String? contactEmail;
  final String? phoneNumber;
  final String? facebookPageUrl;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  // Read-only - set via a file part on the same PUT, never sent as a form
  // field. logoImageUrl is also shown on the storefront; idCard/selfie stay
  // admin-only (see identityVerified's own doc comment elsewhere).
  final String? logoImageUrl;
  final String? idCardUrl;
  final String? selfieUrl;

  // Real, admin-set verification state - lets the vendor see their own
  // review status here instead of only finding out via the storefront
  // badge. Read-only.
  final bool verified;
  final DateTime? verifiedAt;

  final int? maxGuestCapacity;
  // Service Scope & Metrics - mirrors VendorSettingsRequest/Response fields
  // of the same names on the backend.
  final int? maxCustomersPerDay;
  final double? basePrice;
  final int? leadTimeDays;
  final String? storefrontOverview;
  final List<String> operatingAreas;
  final List<VendorEventType> cateredEventTypes;
  // Shown to planners alongside the vendor's QR codes (see PaymentMethodsTab)
  // but lives on the main settings resource, not VendorPaymentMethodController.
  final String? paymentInstructions;

  // Read-only - set via cancellationPolicyFile/refundTermsFile file parts
  // on the same PUT (PDF only), never sent as form fields.
  final String? cancellationPolicyUrl;
  final String? refundTermsUrl;

  const VendorSettings({
    this.slug,
    this.businessName,
    this.description,
    this.ownerName,
    this.businessTypes = const [],
    this.contactEmail,
    this.phoneNumber,
    this.facebookPageUrl,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.logoImageUrl,
    this.idCardUrl,
    this.selfieUrl,
    this.verified = false,
    this.verifiedAt,
    this.maxGuestCapacity,
    this.maxCustomersPerDay,
    this.basePrice,
    this.leadTimeDays,
    this.storefrontOverview,
    this.operatingAreas = const [],
    this.cateredEventTypes = const [],
    this.paymentInstructions,
    this.cancellationPolicyUrl,
    this.refundTermsUrl,
  });

  factory VendorSettings.fromJson(Map<String, dynamic> json) => VendorSettings(
        slug: json['slug'] as String?,
        businessName: json['businessName'] as String?,
        description: json['description'] as String?,
        ownerName: json['ownerName'] as String?,
        businessTypes:
            (json['businessTypes'] as List<dynamic>?)?.map((e) => BusinessTypeApi.fromApi(e as String)).toList() ??
                const [],
        contactEmail: json['contactEmail'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        facebookPageUrl: json['facebookPageUrl'] as String?,
        addressLine1: json['addressLine1'] as String?,
        addressLine2: json['addressLine2'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        postalCode: json['postalCode'] as String?,
        country: json['country'] as String?,
        logoImageUrl: json['logoImageUrl'] as String?,
        idCardUrl: json['idCardUrl'] as String?,
        selfieUrl: json['selfieUrl'] as String?,
        verified: json['verified'] as bool? ?? false,
        verifiedAt: json['verifiedAt'] == null ? null : DateTime.parse(json['verifiedAt'] as String),
        maxGuestCapacity: json['maxGuestCapacity'] as int?,
        maxCustomersPerDay: json['maxCustomersPerDay'] as int?,
        basePrice: (json['basePrice'] as num?)?.toDouble(),
        leadTimeDays: json['leadTimeDays'] as int?,
        storefrontOverview: json['storefrontOverview'] as String?,
        operatingAreas: (json['operatingAreas'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        cateredEventTypes: (json['cateredEventTypes'] as List<dynamic>?)
                ?.map((e) => VendorEventTypeApi.fromApi(e as String))
                .toList() ??
            const [],
        paymentInstructions: json['paymentInstructions'] as String?,
        cancellationPolicyUrl: json['cancellationPolicyUrl'] as String?,
        refundTermsUrl: json['refundTermsUrl'] as String?,
      );

  /// Only the real VendorSettingsRequest form fields - the file-backed and
  /// read-only fields above (logoImageUrl, idCardUrl, verified, slug, ...)
  /// are never part of this.
  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'description': description,
        'ownerName': ownerName,
        'businessTypes': businessTypes.map((e) => e.toApi()).toList(),
        'contactEmail': contactEmail,
        'phoneNumber': phoneNumber,
        'facebookPageUrl': facebookPageUrl,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
        'maxGuestCapacity': maxGuestCapacity,
        'maxCustomersPerDay': maxCustomersPerDay,
        'basePrice': basePrice,
        'leadTimeDays': leadTimeDays,
        'storefrontOverview': storefrontOverview,
        'operatingAreas': operatingAreas,
        'cateredEventTypes': cateredEventTypes.map((e) => e.toApi()).toList(),
        'paymentInstructions': paymentInstructions,
      };

  VendorSettings copyWith({
    String? businessName,
    String? description,
    String? ownerName,
    List<BusinessType>? businessTypes,
    String? contactEmail,
    String? phoneNumber,
    String? facebookPageUrl,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    int? maxGuestCapacity,
    int? maxCustomersPerDay,
    double? basePrice,
    int? leadTimeDays,
    String? storefrontOverview,
    List<String>? operatingAreas,
    List<VendorEventType>? cateredEventTypes,
    String? paymentInstructions,
  }) {
    return VendorSettings(
      slug: slug,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      ownerName: ownerName ?? this.ownerName,
      businessTypes: businessTypes ?? this.businessTypes,
      contactEmail: contactEmail ?? this.contactEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      facebookPageUrl: facebookPageUrl ?? this.facebookPageUrl,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      logoImageUrl: logoImageUrl,
      idCardUrl: idCardUrl,
      selfieUrl: selfieUrl,
      verified: verified,
      verifiedAt: verifiedAt,
      maxGuestCapacity: maxGuestCapacity ?? this.maxGuestCapacity,
      maxCustomersPerDay: maxCustomersPerDay ?? this.maxCustomersPerDay,
      basePrice: basePrice ?? this.basePrice,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      storefrontOverview: storefrontOverview ?? this.storefrontOverview,
      operatingAreas: operatingAreas ?? this.operatingAreas,
      cateredEventTypes: cateredEventTypes ?? this.cateredEventTypes,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      cancellationPolicyUrl: cancellationPolicyUrl,
      refundTermsUrl: refundTermsUrl,
    );
  }
}
