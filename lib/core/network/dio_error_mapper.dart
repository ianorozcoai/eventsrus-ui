import 'package:dio/dio.dart';

import 'api_exception.dart';
import '../../features/auth/data/models/error_response.dart';

ApiException mapDioError(DioException e) {
  final response = e.response;

  if (response == null) {
    return const ApiException(
      statusCode: null,
      message: 'Could not reach the EventsRUs server. Check your connection and try again.',
    );
  }

  final statusCode = response.statusCode;
  ErrorResponse? parsed;
  if (response.data is Map<String, dynamic>) {
    try {
      parsed = ErrorResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      parsed = null;
    }
  }

  switch (statusCode) {
    case 400:
      return ApiException(
        statusCode: 400,
        message: parsed?.message ?? 'Some required information is missing.',
        fieldErrors: parsed?.fieldErrors,
      );
    case 401:
      return const ApiException(
        statusCode: 401,
        message: 'Your session could not be verified. Please sign in again.',
      );
    case 403:
      return ApiException(
        statusCode: 403,
        message: parsed?.message ?? 'Your account does not currently have access.',
      );
    case 409:
      return ApiException(
        statusCode: 409,
        message: parsed?.message ?? 'This already exists for this account.',
      );
    default:
      return ApiException(
        statusCode: statusCode,
        message: parsed?.message ?? 'Something went wrong. Please try again.',
      );
  }
}
