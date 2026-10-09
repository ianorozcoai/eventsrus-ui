class ErrorResponse {
  final int status;
  final String error;
  final String message;
  final Map<String, String>? fieldErrors;

  const ErrorResponse({
    required this.status,
    required this.error,
    required this.message,
    this.fieldErrors,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => ErrorResponse(
        status: json['status'] as int,
        error: json['error'] as String,
        message: json['message'] as String,
        fieldErrors: (json['fieldErrors'] as Map?)?.cast<String, String>(),
      );
}
