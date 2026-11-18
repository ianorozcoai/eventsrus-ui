/// Body of POST /api/v1/auth/apple (backend AppleAuthRequest).
class AppleAuthRequest {
  final String identityToken;

  /// The RAW nonce; the identity token holds its SHA-256 hex digest.
  final String nonce;
  final String? authorizationCode;

  /// Apple only gives the name the first time a person signs in.
  final String? givenName;
  final String? familyName;

  /// "planner" or "vendor", same meaning as GoogleAuthRequest.intent.
  final String? intent;

  const AppleAuthRequest({
    required this.identityToken,
    required this.nonce,
    this.authorizationCode,
    this.givenName,
    this.familyName,
    this.intent,
  });

  Map<String, dynamic> toJson() => {
        'identityToken': identityToken,
        'nonce': nonce,
        if (authorizationCode != null) 'authorizationCode': authorizationCode,
        if (givenName != null) 'givenName': givenName,
        if (familyName != null) 'familyName': familyName,
        if (intent != null) 'intent': intent,
      };
}
