import 'package:eventsrus_ui/features/auth/data/models/business_type.dart';
import 'package:eventsrus_ui/features/vendor/data/models/vendor_onboarding_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toFormFields sends businessTypes as a list and acceptedTerms as a string', () {
    const request = VendorOnboardingRequest(
      businessName: 'Acme Catering',
      businessTypes: [BusinessType.catering, BusinessType.venue],
      facebookPageUrl: 'https://facebook.com/acme',
      acceptedTerms: true,
    );

    final fields = request.toFormFields();

    expect(fields['businessName'], 'Acme Catering');
    expect(fields['businessTypes'], ['CATERING', 'VENUE']);
    expect(fields['facebookPageUrl'], 'https://facebook.com/acme');
    expect(fields['acceptedTerms'], 'true');
  });

  test('toFormFields omits businessTypes and facebookPageUrl when empty', () {
    const request = VendorOnboardingRequest(businessName: 'Acme Catering');

    final fields = request.toFormFields();

    expect(fields.containsKey('businessTypes'), isFalse);
    expect(fields.containsKey('facebookPageUrl'), isFalse);
    expect(fields['acceptedTerms'], 'false');
  });

  test('toFormFields omits referralCode when null or empty', () {
    const request = VendorOnboardingRequest(businessName: 'Acme Catering', referralCode: '');
    expect(request.toFormFields().containsKey('referralCode'), isFalse);
  });
}
