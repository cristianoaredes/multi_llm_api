import 'dart:convert';

import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

/// Type definition for a validation function that takes a request body
/// and returns a validated object or throws an exception.
typedef ValidationFunction = dynamic Function(Map<String, dynamic> body);

/// Middleware for validating request bodies against schemas.
///
/// This middleware intercepts requests and validates their bodies against
/// provided validation functions before passing them to handlers.
/// If validation fails, it returns an appropriate error response.
class ValidationMiddleware {
  /// Logger for this middleware.
  static final Logger _log = Logger('ValidationMiddleware');

  /// Creates middleware that validates request bodies for specific methods and paths.
  ///
  /// [validations] is a map where keys are request paths and values are maps
  /// of HTTP methods to validation functions.
  ///
  /// Example:
  /// ```dart
  /// final validationMiddleware = ValidationMiddleware.create({
  ///   '/api/v1/auth/login': {
  ///     'POST': (body) => LoginRequestDto.fromJson(body),
  ///   },
  /// });
  /// ```
  static Middleware create(
    Map<String, Map<String, ValidationFunction>> validations,
  ) {
    return (Handler innerHandler) {
      return (Request request) async {
        final path = '/${request.url.path}';
        final method = request.method;

        // Check if this path and method require validation
        final pathValidations = validations[path];
        if (pathValidations == null) {
          return innerHandler(request);
        }

        final validationFn = pathValidations[method];
        if (validationFn == null) {
          return innerHandler(request);
        }

        // Only validate requests with bodies
        if (method == 'GET' || method == 'HEAD' || method == 'DELETE') {
          return innerHandler(request);
        }

        try {
          // Read and parse the request body
          final bodyBytes = await request.read().toList();
          if (bodyBytes.isEmpty) {
            throw BadRequestException('Request body cannot be empty');
          }

          final bodyString = utf8.decode(bodyBytes.expand((i) => i).toList());
          if (bodyString.trim().isEmpty) {
            throw BadRequestException('Request body cannot be empty');
          }
          
          final dynamic jsonBody;
          try {
            jsonBody = jsonDecode(bodyString);
          } catch (e) {
            throw BadRequestException('Invalid JSON in request body');
          }

          if (jsonBody is! Map<String, dynamic>) {
            throw BadRequestException('Request body must be a JSON object');
          }

          // Apply the validation function
          try {
            validationFn(jsonBody);
          } catch (e) {
            if (e is FormatException) {
              throw BadRequestException('Validation error: ${e.message}');
            }
            throw BadRequestException('Validation error: $e');
          }

          // Recreate the request with the validated body
          final updatedRequest = request.change(
            body: bodyString,
          );

          return innerHandler(updatedRequest);
        } on BadRequestException catch (e) {
          _log.warning('Validation failed: ${e.message}');
          throw e;
        } catch (e, stackTrace) {
          _log.severe('Unexpected error during validation', e, stackTrace);
          throw BadRequestException('Error validating request: ${e.toString()}');
        }
      };
    };
  }
}
