import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/google_calendar_status.dart';

/// Thrown by [GoogleCalendarApi.connectNative] when the vendor dismissed
/// Google's consent screen without approving - not a real error, callers
/// should just do nothing in that case (same convention as
/// GoogleAuthGateway's sign-in cancellation).
class GoogleCalendarCancelledException implements Exception {
  const GoogleCalendarCancelledException();
}

/// Talks to eventsrus-backend's GoogleCalendarController - status, native
/// connect, and disconnect.
///
/// [connectNative] runs the whole Google consent flow in-app (a Chrome
/// Custom Tab, via flutter_web_auth_2) using a PKCE authorization-code
/// flow against a dedicated "Desktop app"-type Google OAuth client
/// (AppConfig.googleCalendarClientId) - that's the one client type Google
/// lets use an arbitrary custom-scheme redirect with zero Console-side
/// registration, unlike the "Web application" type client eventsrus-web's
/// own Calendar OAuth flow uses (https-only redirects, tied to a browser
/// session). The resulting authorization code is exchanged for a refresh
/// token server-side - the app itself never sees or stores a client
/// secret - via the backend's /exchange endpoint, which then saves the
/// connection exactly like eventsrus-web's flow does.
class GoogleCalendarApi {
  // Google only auto-allows a custom-scheme redirect for a "Desktop app"
  // client when it's this EXACT reverse-DNS-of-the-client-id pattern - an
  // arbitrary scheme (even a valid URI scheme otherwise) gets rejected by
  // Google itself with "Error 400: invalid_request" / "doesn't comply with
  // Google's OAuth 2.0 policy for keeping apps secure", confirmed on-device.
  // Derived from AppConfig.googleCalendarClientId: drop the
  // ".apps.googleusercontent.com" suffix, prefix with
  // "com.googleusercontent.apps.". Single slash after the colon (no
  // authority component), matching Google's own documented examples.
  static const _redirectUri = 'com.googleusercontent.apps.590594963033-9se4maohgfka4crgr5922i739scoq4s5:/oauth2redirect';
  static const _callbackUrlScheme = 'com.googleusercontent.apps.590594963033-9se4maohgfka4crgr5922i739scoq4s5';
  static const _scope = 'https://www.googleapis.com/auth/calendar.events';
  static const _authorizeUrl = 'https://accounts.google.com/o/oauth2/v2/auth';

  final ApiClient _apiClient;

  GoogleCalendarApi(this._apiClient);

  Future<GoogleCalendarStatus> getStatus() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/vendors/me/google-calendar');
      return GoogleCalendarStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> connectNative() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = base64UrlEncode(sha256.convert(utf8.encode(codeVerifier)).bytes).replaceAll('=', '');

    final authorizeUri = Uri.parse(_authorizeUrl).replace(queryParameters: {
      'client_id': AppConfig.googleCalendarClientId,
      'redirect_uri': _redirectUri,
      'response_type': 'code',
      'scope': _scope,
      'access_type': 'offline',
      'prompt': 'consent',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    String result;
    try {
      result = await FlutterWebAuth2.authenticate(url: authorizeUri.toString(), callbackUrlScheme: _callbackUrlScheme);
    } catch (e) {
      if (e.toString().toUpperCase().contains('CANCELED')) {
        throw const GoogleCalendarCancelledException();
      }
      throw const ApiException(statusCode: null, message: 'Could not open the Google consent screen. Please try again.');
    }

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) {
      throw const ApiException(statusCode: null, message: 'Google did not return an authorization code. Please try again.');
    }

    try {
      await _apiClient.dio.post('/api/v1/vendors/me/google-calendar/exchange', data: {
        'code': code,
        'codeVerifier': codeVerifier,
        'redirectUri': _redirectUri,
      });
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> disconnect() async {
    try {
      await _apiClient.dio.delete('/api/v1/vendors/me/google-calendar');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(64, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
