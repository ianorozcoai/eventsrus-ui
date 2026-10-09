import 'dart:io' show Platform;

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
