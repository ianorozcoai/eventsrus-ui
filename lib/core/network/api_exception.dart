class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, String>? fieldErrors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
