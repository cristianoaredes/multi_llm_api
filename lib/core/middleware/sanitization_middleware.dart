import 'dart:convert';

import 'package:api_dart/core/error/app_exception.dart';
import 'package:api_dart/core/utils/input_sanitizer.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

/// Middleware for sanitizing request bodies to prevent injection attacks.
///
/// This middleware intercepts requests and sanitizes their JSON bodies
/// to prevent various types of injection attacks before passing them to handlers.
class SanitizationMiddleware {
  /// Logger for this middleware.
  static final Logger _log = Logger('SanitizationMiddleware');

  /// Creates middleware that sanitizes request bodies.
  ///
  /// The sanitization is applied to all POST, PUT, and PATCH requests.
  static Middleware create() {
    return (Handler innerHandler) {
      return (Request request) async {
        // Only sanitize requests with bodies
        if (!_methodHasBody(request.method)) {
          return innerHandler(request);
        }

        try {
          // Read and parse the request body
          final bodyBytes = await request.read().toList();
          if (bodyBytes.isEmpty) {
            return innerHandler(request);
          }

          final bodyString = utf8.decode(bodyBytes.expand((i) => i).toList());
          if (bodyString.trim().isEmpty) {
            return innerHandler(request);
          }

          final dynamic jsonBody;
          try {
            jsonBody = jsonDecode(bodyString);
          } catch (e) {
            // If it's not valid JSON, pass through without sanitization
            return innerHandler(request);
          }

          // Sanitize the JSON body
          final sanitizedJson = _sanitizeJson(jsonBody);

          // Recreate the request with the sanitized body
          final updatedRequest = request.change(
            body: jsonEncode(sanitizedJson),
          );

          _log.fine(
              'Request body sanitized for ${request.method} ${request.url.path}');
          return innerHandler(updatedRequest);
        } catch (e, stackTrace) {
          _log.severe('Error during request sanitization', e, stackTrace);
          throw InternalServerException(
              'Error processing request: ${e.toString()}');
        }
      };
    };
  }

  /// Sanitizes a JSON value recursively.
  ///
  /// If the value is a Map, sanitizes all string values in the map.
  /// If the value is a List, sanitizes all elements in the list.
  /// If the value is a String, applies appropriate sanitization.
  /// Otherwise, returns the value as is.
  static dynamic _sanitizeJson(dynamic json) {
    if (json is Map) {
      return Map.fromEntries(
        json.entries.map(
          (entry) => MapEntry(
            entry.key,
            _sanitizeJson(entry.value),
          ),
        ),
      );
    } else if (json is List) {
      return json.map(_sanitizeJson).toList();
    } else if (json is String) {
      return InputSanitizer.sanitizeString(json);
    } else {
      return json;
    }
  }

  /// Checks if the HTTP method typically has a request body.
  static bool _methodHasBody(String method) {
    final upperMethod = method.toUpperCase();
    return upperMethod == 'POST' ||
        upperMethod == 'PUT' ||
        upperMethod == 'PATCH';
  }
}
