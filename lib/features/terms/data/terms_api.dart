import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_mapper.dart';

/// Whether the signed-in person has accepted the current Terms & Agreement.
class TermsStatus {
  final bool accepted;
  final String currentVersion;

  const TermsStatus({required this.accepted, required this.currentVersion});

  factory TermsStatus.fromJson(Map<String, dynamic> json) => TermsStatus(
        accepted: json['accepted'] as bool? ?? false,
        currentVersion: json['currentVersion'] as String? ?? '',
      );
}

/// Terms acceptance (Google Play expects users to accept terms that forbid objectionable content before they can
/// post). The text lives on the website; the backend remembers which version each person accepted. See
/// eventsrus-backend's TermsAcceptanceService.
class TermsApi {
  final ApiClient _apiClient;

  TermsApi(this._apiClient);

  Future<TermsStatus> getStatus() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/users/me/terms');
      return TermsStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<TermsStatus> accept() async {
    try {
      final response = await _apiClient.dio.post('/api/v1/users/me/terms-acceptance');
      return TermsStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
