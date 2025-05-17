import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';

/// A middleware that implements rate limiting for API requests.
///
/// This middleware limits the number of requests that can be made by a client
/// within a specified time window. It uses the client's IP address as the
/// identifier for rate limiting.
class RateLimitMiddleware {
  /// Creates a new rate limit middleware.
  ///
  /// [requestsPerWindow] is the maximum number of requests allowed per time window.
  /// [windowDurationInSeconds] is the duration of the time window in seconds.
  /// [pathPrefixes] is a list of path prefixes to apply rate limiting to.
  /// If empty, rate limiting is applied to all paths.
  RateLimitMiddleware({
    this.requestsPerWindow = 60,
    this.windowDurationInSeconds = 60,
    this.pathPrefixes = const [],
    this.bypassHeaderName,
    this.bypassHeaderValue,
  }) {
    // Start the cleanup timer
    _startCleanupTimer();
  }

  /// The maximum number of requests allowed per time window.
  final int requestsPerWindow;

  /// The duration of the time window in seconds.
  final int windowDurationInSeconds;

  /// The path prefixes to apply rate limiting to.
  /// If empty, rate limiting is applied to all paths.
  final List<String> pathPrefixes;

  /// Optional header name that can bypass rate limiting if it matches [bypassHeaderValue].
  final String? bypassHeaderName;

  /// Optional header value that can bypass rate limiting if [bypassHeaderName] is set.
  final String? bypassHeaderValue;

  /// Logger for the rate limit middleware.
  final _log = Logger('RateLimitMiddleware');

  /// A map of client IPs to their request counts and timestamps.
  final _clientRequests = <String, _RateLimitEntry>{};

  /// Timer for cleaning up expired entries.
  Timer? _cleanupTimer;

  /// Creates a middleware function that applies rate limiting.
  Handler middleware(Handler innerHandler) {
    return (request) async {
      // Check if the request should be rate limited
      if (!_shouldRateLimit(request)) {
        return innerHandler(request);
      }

      final clientIp = _getClientIp(request);
      final now = DateTime.now();

      // Check if the client has a rate limit entry
      if (!_clientRequests.containsKey(clientIp)) {
        _clientRequests[clientIp] = _RateLimitEntry(
          count: 1,
          windowStart: now,
        );
        return innerHandler(request);
      }

      final entry = _clientRequests[clientIp]!;

      // Check if the window has expired
      if (now.difference(entry.windowStart).inSeconds > windowDurationInSeconds) {
        // Reset the window
        _clientRequests[clientIp] = _RateLimitEntry(
          count: 1,
          windowStart: now,
        );
        return innerHandler(request);
      }

      // Check if the client has exceeded the rate limit
      if (entry.count >= requestsPerWindow) {
        _log.warning('Rate limit exceeded for client $clientIp');
        
        // Calculate the time until the rate limit resets
        final resetTime = entry.windowStart
            .add(Duration(seconds: windowDurationInSeconds))
            .difference(now)
            .inSeconds;
        
        return Response(429, body: 'Rate limit exceeded. Try again later.', headers: {
          'Content-Type': 'text/plain',
          'X-RateLimit-Limit': requestsPerWindow.toString(),
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': resetTime.toString(),
          'Retry-After': resetTime.toString(),
        });
      }

      // Increment the request count
      entry.count++;
      
      // Calculate remaining requests
      final remaining = requestsPerWindow - entry.count;
      
      // Add rate limit headers to the response
      final response = await innerHandler(request);
      return response.change(headers: {
        ...response.headers,
        'X-RateLimit-Limit': requestsPerWindow.toString(),
        'X-RateLimit-Remaining': remaining.toString(),
        'X-RateLimit-Reset': entry.windowStart
            .add(Duration(seconds: windowDurationInSeconds))
            .difference(now)
            .inSeconds
            .toString(),
      });
    };
  }

  /// Gets the client IP address from the request.
  String _getClientIp(Request request) {
    // Try to get the IP from X-Forwarded-For header first (for proxied requests)
    final forwardedFor = request.headers['x-forwarded-for'];
    if (forwardedFor != null && forwardedFor.isNotEmpty) {
      return forwardedFor.split(',').first.trim();
    }

    // Fall back to the remote address
    return request.context['shelf.io.connection_info'] != null
        ? (request.context['shelf.io.connection_info'] as HttpConnectionInfo)
            .remoteAddress
            .address
        : 'unknown';
  }

  /// Checks if the request should be rate limited.
  bool _shouldRateLimit(Request request) {
    // Check if the request has a bypass header
    if (bypassHeaderName != null &&
        bypassHeaderValue != null &&
        request.headers[bypassHeaderName] == bypassHeaderValue) {
      return false;
    }

    // If no path prefixes are specified, rate limit all paths
    if (pathPrefixes.isEmpty) {
      return true;
    }

    // Check if the request path matches any of the path prefixes
    return pathPrefixes.any((prefix) => request.url.path.startsWith(prefix));
  }

  /// Starts a timer to clean up expired entries.
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupExpiredEntries();
    });
  }

  /// Cleans up expired entries from the client requests map.
  void _cleanupExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _clientRequests.forEach((key, entry) {
      if (now.difference(entry.windowStart).inSeconds > windowDurationInSeconds) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _clientRequests.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _log.fine('Cleaned up ${expiredKeys.length} expired rate limit entries');
    }
  }

  /// Disposes the rate limit middleware.
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _clientRequests.clear();
  }
}

/// A class that represents a rate limit entry for a client.
class _RateLimitEntry {
  /// Creates a new rate limit entry.
  _RateLimitEntry({
    required this.count,
    required this.windowStart,
  });

  /// The number of requests made by the client in the current window.
  int count;

  /// The start time of the current window.
  final DateTime windowStart;
}
