import 'package:dio/dio.dart';

/// Generic API failure, carrying the same top-level `message` Laravel puts
/// on every JSON error response. Mirrors `getErrorMessage` in
/// frontend/src/lib/api/errors.ts.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// A Laravel 422 response: `{ message, errors: { field: [msg, ...] } }`.
/// Mirrors `applyServerErrors` in frontend/src/lib/api/errors.ts — callers
/// read `fieldErrors[field]` to show inline form errors the same way the
/// website maps them onto react-hook-form.
class ApiValidationException extends ApiException {
  ApiValidationException(super.message, this.fieldErrors) : super(statusCode: 422);

  final Map<String, List<String>> fieldErrors;

  /// First error message for a given field, if any.
  String? firstError(String field) => fieldErrors[field]?.firstOrNull;
}

/// Converts a raw [DioException] into an [ApiException]/[ApiValidationException],
/// reading the same `{ message, errors }` body shape Laravel returns on every
/// endpoint in this API.
ApiException apiExceptionFrom(DioException error) {
  final response = error.response;
  final data = response?.data;
  final status = response?.statusCode;

  String message = 'Something went wrong. Please try again.';
  Map<String, List<String>>? errors;

  if (data is Map) {
    final rawMessage = data['message'];
    if (rawMessage is String && rawMessage.isNotEmpty) {
      message = rawMessage;
    }
    final rawErrors = data['errors'];
    if (rawErrors is Map) {
      errors = rawErrors.map(
        (key, value) => MapEntry(key.toString(), List<String>.from(value as List)),
      );
    }
  }

  if (status == 422 && errors != null) {
    return ApiValidationException(message, errors);
  }

  return ApiException(message, statusCode: status);
}
