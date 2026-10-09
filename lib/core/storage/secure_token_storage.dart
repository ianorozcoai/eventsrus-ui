import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredSession {
  final String token;
  final String refreshToken;
  final String role;
  final DateTime expiry;
  final String? signupIntent;
  final String? firstName;
  final String? email;
  final String? plan;
  final DateTime? planExpiresAt;

  const StoredSession({
    required this.token,
    required this.refreshToken,
    required this.role,
    required this.expiry,
    this.signupIntent,
    this.firstName,
    this.email,
    this.plan,
    this.planExpiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class SecureTokenStorage {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _roleKey = 'auth_role';
  static const _expiryKey = 'auth_expiry';
  static const _signupIntentKey = 'auth_signup_intent';
  static const _firstNameKey = 'auth_first_name';
  static const _emailKey = 'auth_email';
  static const _planKey = 'auth_plan';
  static const _planExpiresAtKey = 'auth_plan_expires_at';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> save({
    required String token,
    required String refreshToken,
    required String role,
    required int expiresInSeconds,
    String? signupIntent,
    String? firstName,
    String? email,
    String? plan,
    DateTime? planExpiresAt,
  }) async {
    final expiry = DateTime.now().add(Duration(seconds: expiresInSeconds));
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _expiryKey, value: expiry.toIso8601String());
    await _storage.write(key: _signupIntentKey, value: signupIntent);
    await _storage.write(key: _firstNameKey, value: firstName);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _planKey, value: plan);
    await _storage.write(
      key: _planExpiresAtKey,
      value: planExpiresAt?.toIso8601String(),
    );
  }

  /// Updates just the token pair + expiry after a silent refresh
  /// (ApiClient's 401 interceptor / AuthController.restoreSession) -
  /// everything else (role, plan, ...) is unaffected by a refresh and
  /// stays as already stored.
  Future<void> saveRefreshedTokens({
    required String token,
    required String refreshToken,
    required int expiresInSeconds,
  }) async {
    final expiry = DateTime.now().add(Duration(seconds: expiresInSeconds));
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _expiryKey, value: expiry.toIso8601String());
  }

  Future<StoredSession?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final role = await _storage.read(key: _roleKey);
    final expiryRaw = await _storage.read(key: _expiryKey);

    if (token == null || refreshToken == null || role == null || expiryRaw == null) {
      return null;
    }

    final expiry = DateTime.tryParse(expiryRaw);
    if (expiry == null) {
      return null;
    }

    final signupIntent = await _storage.read(key: _signupIntentKey);
    final firstName = await _storage.read(key: _firstNameKey);
    final email = await _storage.read(key: _emailKey);
    final plan = await _storage.read(key: _planKey);
    final planExpiresAtRaw = await _storage.read(key: _planExpiresAtKey);

    return StoredSession(
      token: token,
      refreshToken: refreshToken,
      role: role,
      expiry: expiry,
      signupIntent: signupIntent,
      firstName: firstName,
      email: email,
      plan: plan,
      planExpiresAt:
          planExpiresAtRaw == null ? null : DateTime.tryParse(planExpiresAtRaw),
    );
  }

  Future<void> updatePlan({String? plan, DateTime? planExpiresAt}) async {
    await _storage.write(key: _planKey, value: plan);
    await _storage.write(
      key: _planExpiresAtKey,
      value: planExpiresAt?.toIso8601String(),
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _expiryKey);
    await _storage.delete(key: _signupIntentKey);
    await _storage.delete(key: _firstNameKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _planKey);
    await _storage.delete(key: _planExpiresAtKey);
  }
}
