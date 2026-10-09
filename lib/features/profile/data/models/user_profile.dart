/// Mirrors eventsrus-backend's {@code UserProfileResponse}/{@code UpdateProfileRequest} -
/// the same shape serves both the GET and PUT bodies (see UserApi).
class UserProfile {
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;

  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        mobileNumber: json['mobileNumber'] as String? ?? '',
        addressLine1: json['addressLine1'] as String?,
        addressLine2: json['addressLine2'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        postalCode: json['postalCode'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobileNumber': mobileNumber,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'postalCode': postalCode,
      };
}
