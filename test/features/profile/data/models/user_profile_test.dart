import 'package:eventsrus_ui/features/profile/data/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips through toJson/fromJson', () {
    const profile = UserProfile(
      firstName: 'Ian',
      lastName: 'Orozco',
      email: 'ian@example.com',
      mobileNumber: '09171234567',
      addressLine1: '123 Main St',
      city: 'Quezon City',
      state: 'Metro Manila',
      postalCode: '1100',
    );

    final roundTripped = UserProfile.fromJson(profile.toJson());

    expect(roundTripped.firstName, 'Ian');
    expect(roundTripped.email, 'ian@example.com');
    expect(roundTripped.city, 'Quezon City');
    expect(roundTripped.addressLine2, isNull);
  });

  test('fromJson tolerates missing optional address fields', () {
    final profile = UserProfile.fromJson({
      'firstName': 'Ian',
      'lastName': 'Orozco',
      'email': 'ian@example.com',
      'mobileNumber': '09171234567',
    });

    expect(profile.addressLine1, isNull);
    expect(profile.city, isNull);
  });
}
