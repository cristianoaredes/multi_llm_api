import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

/// Middleware for logging incoming requests and their results.
///
/// Logs request start, completion status, and duration.
/// Also logs any errors that occur during request processing.
Middleware logMiddleware() {
  final log = Logger('RequestLogger');

  return (Handler innerHandler) {
    return (Request request) {
      final watch = Stopwatch()..start();

      FutureOr<Response> onResponse(Response response) {
        final elapsedTime = watch.elapsed;
        // Format log message
        log.info(
          '${response.statusCode} ${request.method} ${request.requestedUri} '
          '(${elapsedTime.inMilliseconds}ms)',
        );
        return response;
      }

      FutureOr<Response> onError(Object error, StackTrace stackTrace) {
        final elapsedTime = watch.elapsed;
        if (error is HijackException) throw error;
        // Format log message
        log.severe(
          'Error handling ${request.method} ${request.requestedUri} '
          '(${elapsedTime.inMilliseconds}ms)',
          error,
          stackTrace,
        );
        // Rethrow the original error if it's an Exception or Error,
        // otherwise wrap it in a generic Exception.
        if (error is Exception || error is Error) {
          throw error; // Rethrow recognized error types
        }
        // Wrap unrecognized objects in an Exception before throwing
        throw Exception('Unhandled object thrown during request: $error');
      }

      // Log request start
      log.fine('Received ${request.method} ${request.requestedUri}');

      return Future.sync(() => innerHandler(request))
          .then(onResponse, onError: onError);
    };
  };
}
