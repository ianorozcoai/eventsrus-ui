import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../notifications/data/device_token_api.dart';
import '../data/auth_api.dart';
import '../data/google_auth_gateway.dart';
import '../data/models/auth_response.dart';
import '../data/models/google_auth_request.dart';
import '../data/models/plan_tier.dart';
import '../data/models/role.dart';
import '../data/models/signup_intent.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  final AuthApi _authApi;
  final SecureTokenStorage _storage;
  final DeviceTokenApi _deviceTokenApi;

  AuthController({
    required AuthApi authApi,
    required SecureTokenStorage storage,
    required DeviceTokenApi deviceTokenApi,
    // ignore: prefer_initializing_formals
  }) : _authApi = authApi,
       // ignore: prefer_initializing_formals
       _storage = storage,
       // ignore: prefer_initializing_formals
       _deviceTokenApi = deviceTokenApi;

  AuthStatus status = AuthStatus.unknown;
  String? token;
  String? _refreshToken;
  Role? role;
  SignupIntent? signupIntent;
  String? firstName;
  String? email;
  PlanTier? plan;
  DateTime? planExpiresAt;
  bool isLoading = false;
  String? errorMessage;

  Future<void> restoreSession() async {
    final session = await _storage.read();
    if (session == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (!session.isExpired) {
      _applyStoredSession(session);
      status = AuthStatus.authenticated;
      notifyListeners();
      unawaited(PushNotificationService.instance.registerDevice(_deviceTokenApi));
      return;
    }

    // The short-lived access token has expired (hourly) - try the
    // long-lived refresh token before giving up and sending the user back
    // to login, so a session genuinely stays signed in across app
    // restarts the way a native app is expected to (see AuthController's
    // own PR description / the backend's RefreshTokenService).
    try {
      final response = await _authApi.refresh(session.refreshToken);
      await applyAuthResponse(response);
    } on ApiException {
      // Refresh token itself is unknown/revoked/past its own ~30-day
      // expiry - a real re-login is unavoidable here.
      await _storage.clear();
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void _applyStoredSession(StoredSession session) {
    token = session.token;
    _refreshToken = session.refreshToken;
    role = RoleApi.fromApi(session.role);
    signupIntent = SignupIntentApi.fromApiNullable(session.signupIntent);
    firstName = session.firstName;
    email = session.email;
    plan = PlanTierApi.fromApiNullable(session.plan);
    planExpiresAt = session.planExpiresAt;
  }

  /// [intent] is the role-picker's choice ("planner" or "vendor" door) -
  /// see GoogleAuthRequest's doc comment. Passed through untouched on an
  /// existing account too, so the backend can reject a cross-door login
  /// attempt (AccountIdentityConflictException) with a clear message.
  Future<void> completeLogin(String idToken, {SignupIntent? intent}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _authApi.authenticateWithGoogle(
        GoogleAuthRequest(idToken: idToken, intent: intent?.toApi()),
      );
      await applyAuthResponse(response);
    } on ApiException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      notifyListeners();
      rethrow;
    }
  }

  /// Persists a fresh AuthResponse (from login or becoming a vendor) and
  /// updates in-memory state. Shared so any flow that yields a new token
  /// applies it the same way.
  Future<void> applyAuthResponse(AuthResponse response) async {
    await _storage.save(
      token: response.token,
      refreshToken: response.refreshToken,
      role: response.role.toApi(),
      expiresInSeconds: response.expiresIn,
      signupIntent: response.signupIntent?.toApi(),
      firstName: response.firstName,
      email: response.email,
      plan: response.plan?.toApi(),
      planExpiresAt: response.planExpiresAt,
    );
    token = response.token;
    _refreshToken = response.refreshToken;
    role = response.role;
    signupIntent = response.signupIntent;
    firstName = response.firstName;
    email = response.email;
    plan = response.plan;
    planExpiresAt = response.planExpiresAt;
    status = AuthStatus.authenticated;
    isLoading = false;
    notifyListeners();
    unawaited(PushNotificationService.instance.registerDevice(_deviceTokenApi));
  }

  /// Refreshes plan/expiry only (e.g. after a subscription purchase),
  /// without touching the session token.
  Future<void> applyPlanUpdate({
    required PlanTier? plan,
    DateTime? planExpiresAt,
  }) async {
    await _storage.updatePlan(
      plan: plan?.toApi(),
      planExpiresAt: planExpiresAt,
    );
    this.plan = plan;
    this.planExpiresAt = planExpiresAt;
    notifyListeners();
  }

  Future<void> logout() async {
    await PushNotificationService.instance.unregisterDevice();
    final refreshToken = _refreshToken;
    if (refreshToken != null) {
      // Best-effort - a failed revoke (offline, server hiccup) shouldn't
      // block the user from logging out locally.
      try {
        await _authApi.logout(refreshToken);
      } catch (_) {}
    }
    await _storage.clear();
    await GoogleAuthGateway.instance.signOut();
    token = null;
    _refreshToken = null;
    role = null;
    signupIntent = null;
    firstName = null;
    email = null;
    plan = null;
    planExpiresAt = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
