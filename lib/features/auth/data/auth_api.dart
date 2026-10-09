import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import 'models/auth_response.dart';
import 'models/google_auth_request.dart';

class AuthApi {
  final ApiClient _apiClient;

  AuthApi(this._apiClient);

  Future<AuthResponse> authenticateWithGoogle(GoogleAuthRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/auth/google',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Redeems a refresh token for a fresh access/refresh token pair - see
  /// AuthController#refresh. Throws ApiException (401) if it's unknown,
  /// already used, or past its own ~30-day expiry.
  Future<AuthResponse> refresh(String refreshToken) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Best-effort - revokes this one refresh token server-side so it can't
  /// be redeemed again. Callers should still clear local session state even
  /// if this fails (e.g. offline logout).
  Future<void> logout(String refreshToken) async {
    try {
      await _apiClient.dio.post(
        '/api/v1/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
