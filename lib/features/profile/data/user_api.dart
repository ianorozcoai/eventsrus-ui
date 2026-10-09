import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../auth/data/models/auth_response.dart';
import 'models/user_profile.dart';

class UserApi {
  final ApiClient _apiClient;

  UserApi(this._apiClient);

  Future<UserProfile> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/users/me/profile');
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Returns a fresh [AuthResponse] (not just the saved profile) - email is
  /// editable here and is also the JWT subject, so a changed email needs a
  /// reissued token. Callers must feed this through
  /// `AuthController.applyAuthResponse` or the app's cached session will
  /// still carry the old email/claims. See eventsrus-backend's
  /// UserController#updateProfile for why.
  Future<AuthResponse> updateProfile(UserProfile profile) async {
    try {
      final response = await _apiClient.dio.put('/api/v1/users/me/profile', data: profile.toJson());
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
