import '../../../auth/data/models/business_type.dart';

class VendorOnboardingRequest {
  final String businessName;
  // Backend requires at least one (`@NotEmpty List<BusinessType> businessTypes`
  // on VendorOnboardingRequest) - mirrors web's multi-select business type
  // picker, not a single value.
  final List<BusinessType> businessTypes;
  final String? ownerName;
  final String? description;
  final String? contactEmail;
  final String? phoneNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? facebookPageUrl;
  // Required by the backend (`@AssertTrue boolean acceptedTerms`) - omitting
  // it entirely made every onboarding submission fail validation, since a
  // missing form field binds to `false` for a primitive boolean.
  final bool acceptedTerms;
  // Another vendor's referral code, if this vendor signed up through a
  // referral link - optional, silently ignored server-side if
  // missing/invalid (see UserService#becomeVendor on the backend).
  final String? referralCode;
  // Admin-configured code granting the full free trial with no paywall
  // (see PromoCodeService) - unlike referralCode, an invalid value rejects
  // the whole submission server-side (InvalidPromoCodeException, 400).
  final String? promoCode;

  const VendorOnboardingRequest({
    required this.businessName,
    this.businessTypes = const [],
    this.ownerName,
    this.description,
    this.contactEmail,
    this.phoneNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.facebookPageUrl,
    this.acceptedTerms = false,
    this.referralCode,
    this.promoCode,
  });

  Map<String, dynamic> toFormFields() => {
        'businessName': businessName,
        if (businessTypes.isNotEmpty)
          'businessTypes': businessTypes.map((t) => t.toApi()).toList(),
        if (ownerName != null) 'ownerName': ownerName!,
        if (description != null) 'description': description!,
        if (contactEmail != null) 'contactEmail': contactEmail!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (addressLine1 != null) 'addressLine1': addressLine1!,
        if (addressLine2 != null) 'addressLine2': addressLine2!,
        if (city != null) 'city': city!,
        if (state != null) 'state': state!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (country != null) 'country': country!,
        if (facebookPageUrl != null && facebookPageUrl!.isNotEmpty) 'facebookPageUrl': facebookPageUrl!,
        'acceptedTerms': acceptedTerms.toString(),
        if (referralCode != null && referralCode!.isNotEmpty) 'referralCode': referralCode!,
        if (promoCode != null && promoCode!.isNotEmpty) 'promoCode': promoCode!,
      };
}
