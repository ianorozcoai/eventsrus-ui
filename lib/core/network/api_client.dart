import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_token_storage.dart';

class ApiClient {
  final Dio dio;
  final SecureTokenStorage _storage;

  // Guards against piling up concurrent refreshes when several requests
  // 401 around the same moment (e.g. a screen firing off a handful of
  // parallel GETs right as the access token expires) - they all await the
  // same in-flight refresh instead of each redeeming (and invalidating,
  // since refresh tokens are single-use/rotating - see
  // RefreshTokenService) the previous one's refresh token out from under
  // each other.
  Future<String?>? _refreshing;

  ApiClient({required SecureTokenStorage storage})
      : _storage = storage,
        dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.backendBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = await storage.read();
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.token}';
          }
          handler.next(options);
        },
        // Transparent silent-refresh-and-retry for a session that's still
        // in the foreground when its hourly access token expires -
        // AuthController.restoreSession handles the equivalent case for a
        // cold app start. Not an auth endpoint 401ing (the login call
        // itself rejecting a bad Google token, say) - that's a real
        // failure, not an expired-session one, so it's left alone.
        onError: (error, handler) async {
          final isAuthEndpoint = error.requestOptions.path.startsWith('/api/v1/auth/');
          if (error.response?.statusCode != 401 || isAuthEndpoint) {
            handler.next(error);
            return;
          }

          final newToken = await _refreshAccessToken();
          if (newToken == null) {
            handler.next(error);
            return;
          }

          try {
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newToken';
            handler.resolve(await dio.fetch(retryOptions));
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  /// Null if there's no session to refresh, or the refresh itself was
  /// rejected (refresh token expired/revoked) - the caller just surfaces
  /// the original 401 in that case, which bubbles up as the usual
  /// ApiException the UI already knows how to show; the user's next
  /// natural AuthGate rebuild (or app restart) routes them back to login
  /// via AuthController.restoreSession hitting the same rejection.
  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final session = await _storage.read();
    if (session == null) return null;

    try {
      // A bare Dio, not `dio` - this must never go through this same
      // interceptor (infinite recursion if a refresh itself ever 401s).
      final response = await Dio(BaseOptions(baseUrl: AppConfig.backendBaseUrl)).post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': session.refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      final newToken = data['token'] as String;
      await _storage.saveRefreshedTokens(
        token: newToken,
        refreshToken: data['refreshToken'] as String,
        expiresInSeconds: data['expiresIn'] as int,
      );
      return newToken;
    } catch (_) {
      return null;
    }
  }
}
