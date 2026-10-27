import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'models/apple_auth_request.dart';

/// The only file that imports `sign_in_with_apple` (same idea as GoogleAuthGateway).
/// Sign in with Apple is offered on iPhone only (App Store guideline 4.8).
class AppleAuthGateway {
  AppleAuthGateway._();

  static final AppleAuthGateway instance = AppleAuthGateway._();

  /// A random value only this sign-in attempt knows. Apple is given its SHA-256 hex
  /// digest and puts it in the identity token; the backend hashes the raw value it
  /// gets from us and compares, so a stolen token cannot be replayed.
  static String generateNonce([Random? random]) {
    final r = random ?? Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String sha256Hex(String value) => sha256.convert(utf8.encode(value)).toString();

  /// Interactive sign-in. Returns null if the person dismissed the Apple sheet (not an error).
  /// Rethrows [SignInWithAppleAuthorizationException] for real failures.
  Future<AppleAuthRequest?> signIn({String? intent}) async {
    final nonce = generateNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: sha256Hex(nonce),
      );
      final identityToken = credential.identityToken;
      if (identityToken == null) return null;
      return AppleAuthRequest(
        identityToken: identityToken,
        nonce: nonce,
        authorizationCode: credential.authorizationCode,
        givenName: credential.givenName,
        familyName: credential.familyName,
        intent: intent,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }
}
