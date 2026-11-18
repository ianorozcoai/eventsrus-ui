import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';

/// Thrown on iPhone when the build has no Google iOS client id yet (see AppConfig.googleIosClientId).
class GoogleSignInNotConfigured implements Exception {
  const GoogleSignInNotConfigured();
}

/// The only file in this app that imports `google_sign_in` directly.
/// Everything else talks to Google Sign-In through this gateway.
class GoogleAuthGateway {
  GoogleAuthGateway._();

  static final GoogleAuthGateway instance = GoogleAuthGateway._();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    // iPhone needs its own iOS client id; Android does not (see below).
    final iosClientId = AppConfig.googleIosClientId;
    if (defaultTargetPlatform == TargetPlatform.iOS && iosClientId == null) {
      throw const GoogleSignInNotConfigured();
    }
    // clientId is ignored on Android (and is only passed on iOS) - the backend only ever verifies
    // tokens audienced to the existing Web-application OAuth client, so
    // that's requested here as serverClientId instead. See
    // eventsrus-backend's GoogleTokenVerifierService.
    await GoogleSignIn.instance.initialize(
      clientId: iosClientId,
      serverClientId: AppConfig.googleWebClientId,
    );
    _initialized = true;
  }

  /// Interactive sign-in. Returns the ID token, or `null` if the user
  /// dismissed the account picker (not an error) - callers should just do
  /// nothing in that case rather than show an error message. Rethrows
  /// [GoogleSignInException] for real failures.
  Future<String?> signIn() async {
    await ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() => GoogleSignIn.instance.signOut();
}
