import 'dart:convert'; // dart:async was unused

import 'package:api_dart/core/error/app_exception.dart';
import 'package:api_dart/core/presentation/dtos/error_response_dto.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

// Create a logger for this middleware
final _log = Logger('ErrorHandlerMiddleware');

/// Middleware that catches errors and converts them into standard JSON
/// responses.
///
/// Handles known [AppException] types by returning their corresponding status
/// code and a JSON body with `errorCode` and `message`. Catches unexpected
/// errors and returns a generic 500 Internal Server Error response.
Middleware errorHandlerMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        // Attempt to handle the request normally
        final response = await innerHandler(request);
        return response;
      } on AppException catch (e, stackTrace) {
        // Handle known application exceptions
        // Replace print with logger
        _log.warning(
          'AppException caught: ${e.message}',
          e, // Pass exception object
          stackTrace, // Pass stack trace
        );
        // Use the new errorCode property
        final errorResponse = ErrorResponseDto(
          code: e.errorCode,
          message: e.message,
        );
        return Response(
          e.statusCode,
          body: jsonEncode(errorResponse.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e, stackTrace) {
        // Handle unexpected errors
        // Replace print with logger
        _log.severe('Unhandled exception caught', e, stackTrace);
        // Return a generic 500 response
        // Standardize unexpected error response
        const errorResponse = ErrorResponseDto(
          code: 'INTERNAL_SERVER_ERROR',
          message: 'An unexpected error occurred on the server.',
        );
        return Response.internalServerError(
          body: jsonEncode(errorResponse.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}
