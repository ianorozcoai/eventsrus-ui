import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

class AppConfig {
  AppConfig._();

  // Always wins when provided, e.g. for a real device on the dev LAN:
  // flutter run --dart-define=BACKEND_BASE_URL=http://192.168.x.x:8080
  static const String _backendBaseUrlOverride =
      String.fromEnvironment('BACKEND_BASE_URL');

  static String get backendBaseUrl {
    if (_backendBaseUrlOverride.isNotEmpty) return _backendBaseUrlOverride;
    // 10.0.2.2 is the Android *emulator's* fixed alias for the host
    // machine's localhost - it does NOT work on a real device, which
    // needs the --dart-define override above instead.
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  // RevenueCat PUBLIC SDK key, supplied at build time. Android (goog_...):
  // flutter build appbundle --dart-define=RC_API_KEY=goog_xxx
  // iOS (appl_...): flutter build ipa --dart-define=RC_API_KEY_IOS=appl_xxx
  // Never hard-code it and never commit it. A test_ key (RevenueCat Test Store)
  // is ignored unless the build also sets --dart-define=ALLOW_TEST_STORE=true,
  // so a release build can never ship with the fake store by accident.
  static const String _revenueCatApiKey = String.fromEnvironment('RC_API_KEY');
  static const String _revenueCatApiKeyIos = String.fromEnvironment('RC_API_KEY_IOS');
  static const bool _allowTestStore = bool.fromEnvironment('ALLOW_TEST_STORE');

  /// The key to configure purchases_flutter with, or null when none is usable
  /// (the plan screen then shows its safe "not available yet" state).
  static String? get revenueCatApiKey => revenueCatKeyFor(
        defaultTargetPlatform,
        androidKey: _revenueCatApiKey,
        iosKey: _revenueCatApiKeyIos,
        allowTestStore: _allowTestStore,
      );

  /// Picks the key for [platform]. On iOS only an Apple key (appl_...) or an
  /// allowed test_ key counts, so an Android key can never be used there by
  /// mistake. Android behaviour is exactly [usableRevenueCatKey].
  static String? revenueCatKeyFor(
    TargetPlatform platform, {
    required String androidKey,
    required String iosKey,
    required bool allowTestStore,
  }) {
    if (platform != TargetPlatform.iOS) {
      return usableRevenueCatKey(androidKey, allowTestStore: allowTestStore);
    }
    final key = usableRevenueCatKey(iosKey, allowTestStore: allowTestStore);
    if (key == null) return null;
    return key.startsWith('appl_') || key.startsWith('test_') ? key : null;
  }

  static String? usableRevenueCatKey(String key, {required bool allowTestStore}) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('test_') && !allowTestStore) return null;
    return trimmed;
  }

  // Package name Google Play knows the app by, and the subscription product id
  // created in Play Console - used for the "Manage subscription" deep link.
  static const String androidPackageName = 'com.eventsrus.eventsrus_ui';
  static const String playSubscriptionId = 'supplier_pro';

  static const String googleWebClientId =
      '590594963033-29a013v91o79jnf72pkcdnvf6ue3egej.apps.googleusercontent.com';

  // The Google Calendar native-connect flow (GoogleCalendarApi.connectNative)
  // needs its own OAuth client of type "Desktop app" - that's the one type
  // Google lets use an arbitrary custom-scheme redirect
  // (com.eventsrus.eventsrus_ui://oauth2redirect) with no Console-side
  // redirect-URI registration, unlike the "Web application" type client
  // eventsrus-web's own Calendar OAuth flow uses (https-only redirects).
  // A client ID is public by design (safe to embed), same as
  // googleWebClientId above - only its secret (server-side only, in
  // eventsrus-backend's config) is sensitive.
  static const String googleCalendarClientId =
      '590594963033-9se4maohgfka4crgr5922i739scoq4s5.apps.googleusercontent.com';

  // eventsrus-web runs as its own separate app (port 8081 locally, vs. the
  // backend's 8080 above) - only needed for flows that must happen in the
  // vendor's own browser session rather than as a direct API call, e.g. the
  // Google Calendar OAuth consent redirect (GoogleCalendarOAuthController).
  // flutter run --dart-define=WEB_BASE_URL=http://192.168.x.x:8081
  static const String _webBaseUrlOverride = String.fromEnvironment('WEB_BASE_URL');

  static String get webBaseUrl {
    if (_webBaseUrlOverride.isNotEmpty) return _webBaseUrlOverride;
    // 10.0.2.2 is the Android *emulator's* fixed alias for the host
    // machine's localhost - see backendBaseUrl above for the same caveat.
    if (Platform.isAndroid) return 'http://10.0.2.2:8081';
    return 'http://localhost:8081';
  }
}
