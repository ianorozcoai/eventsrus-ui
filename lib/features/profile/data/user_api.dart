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

  /// Starts the 30-day account-deletion grace period (Google Play requires an
  /// in-app way to delete an account). Returns when the account will be
  /// permanently scrubbed. Throws an [ApiException] with status 409 and a
  /// plain-language reason if the user must first cancel a subscription or
  /// an upcoming booking. Signing in again within the grace period cancels
  /// it - see eventsrus-backend's AccountDeletionService.
  Future<DateTime> requestAccountDeletion() async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/users/me/deletion-request',
        data: {'confirmText': 'DELETE', 'acceptedTerms': true},
      );
      final json = response.data as Map<String, dynamic>;
      return DateTime.parse(json['scheduledFor'] as String).toLocal();
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
