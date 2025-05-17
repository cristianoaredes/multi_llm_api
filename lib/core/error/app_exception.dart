/// {@template app_exception}
/// Base class for custom application exceptions.
///
/// Provides a standard structure for errors with a message, status code,
/// and a specific error code string.
/// {@endtemplate}
class AppException implements Exception {
  /// {@macro app_exception}
  AppException(this.message, this.statusCode, this.errorCode);

  /// A human-readable message describing the error.
  final String message;

  /// The HTTP status code associated with this error.
  final int statusCode;

  /// A standardized error code string.
  final String errorCode;

  @override
  String toString() => 'AppException ($statusCode - $errorCode): $message';
}

/// {@template bad_request_exception}
/// Exception for bad requests (HTTP 400).
///
/// Typically used for client-side errors like invalid input or malformed requests.
/// {@endtemplate}
class BadRequestException extends AppException {
  /// {@macro bad_request_exception}
  BadRequestException(String message) : super(message, 400, 'BAD_REQUEST');
}

/// {@template unauthorized_exception}
/// Exception for unauthorized access (HTTP 401).
///
/// Used when authentication is required and has failed or has not yet
/// been provided.
/// {@endtemplate}
class UnauthorizedException extends AppException {
  /// {@macro unauthorized_exception}
  UnauthorizedException(String message) : super(message, 401, 'UNAUTHORIZED');
}

/// {@template forbidden_exception}
// Removed duplicate template tag above
/// Exception for forbidden access (HTTP 403).
///
/// Used when the server understands the request but refuses to authorize it,
/// often due to insufficient permissions.
/// {@endtemplate}
class ForbiddenException extends AppException {
  /// {@macro forbidden_exception}
  ForbiddenException(String message) : super(message, 403, 'FORBIDDEN');
}

/// {@template not_found_exception}
/// Exception for resources not found (HTTP 404).
///
/// Used when the requested resource could not be found on the server.
/// {@endtemplate}
class NotFoundException extends AppException {
  /// {@macro not_found_exception}
  NotFoundException(String message) : super(message, 404, 'NOT_FOUND');
}

/// {@template internal_server_exception}
/// Exception for internal server errors (HTTP 500).
///
/// Used for unexpected server-side errors that prevented the request
/// from being fulfilled.
/// Note: Usually caught by the generic `errorHandlerMiddleware`,
/// but can be thrown explicitly if needed.
/// {@endtemplate}
class InternalServerException extends AppException {
  /// {@macro internal_server_exception}
  InternalServerException(String message)
      : super(
          message,
          500,
          'INTERNAL_SERVER_ERROR',
        );
}

// Consider adding more specific exceptions if needed, e.g., ValidationException
// class ValidationException extends BadRequestException {
//   final Map<String, String> errors;
//   ValidationException(this.errors)
//       : super('Validation failed', 400, 'VALIDATION_ERROR');
// }
