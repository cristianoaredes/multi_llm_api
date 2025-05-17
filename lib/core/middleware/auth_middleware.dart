import 'package:multi_llm_api/core/di/injector.dart';
import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:multi_llm_api/features/auth/domain/auth_service_interface.dart';
import 'package:shelf/shelf.dart';

// List of paths *relative to the API base* that do not require authentication
// The /api/v1 prefix will be handled separately.
const _unprotectedApiPaths = {
  '/auth/login', // e.g., /api/v1/auth/login
  '/auth/register', // e.g., /api/v1/auth/register
  '/auth/refresh', // e.g., /api/v1/auth/refresh
};

// Top-level unprotected paths (outside /api/v1)
const _topLevelUnprotectedPaths = {
  '/health', // e.g., /health
  '/docs',   // Making Swagger docs publicly accessible
  '/openapi', // Public access to OpenAPI documentation
  '/openapi/openapi.yaml', // Direct access to YAML file
};

const _apiPrefix = '/api/v1'; // Define the API prefix

/// Middleware for handling authentication.
///
/// Checks for a 'Bearer' token in the 'Authorization' header for
/// protected routes.
/// Unprotected routes (like health checks, login, or register) are allowed through.
/// Throws [UnauthorizedException] if authentication fails for a
/// protected route.
Middleware authMiddleware() {
  // Inject the auth service interface
  final authService = injector<IAuthService>();

  return (innerHandler) {
    return (request) async {
      final path = '/${request.url.path}'; // Ensure leading slash

      // Check top-level unprotected paths first
      if (_topLevelUnprotectedPaths.contains(path)) {
        return innerHandler(request);
      }
      
      // Handle requests for favicon.ico without authentication
      if (path == '/favicon.ico') {
        return innerHandler(request);
      }

      // Check if the request is under the API prefix
      if (path.startsWith(_apiPrefix)) {
        final apiRelativePath = path.substring(_apiPrefix.length);
        // Check API-specific unprotected paths
        if (_unprotectedApiPaths.contains(apiRelativePath)) {
          return innerHandler(request);
        }
      } else {
        // If not a top-level unprotected path and not under /api/v1,
        // treat as protected by default (or adjust logic if needed).
        throw UnauthorizedException('Access denied.');
      }

      // --- Authentication required for paths beyond this point ---

      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        throw UnauthorizedException('Missing or invalid authorization header');
      }
      
      final token = authHeader.substring(7); // Extract token part
      
      try {
        // Verify the token and get the user
        final user = await authService.verifyToken(token);
        
        // Add user context to the request
        return innerHandler(
          request.change(
            context: {
              'user': user,
              'userId': user.id,
              'userRole': user.role,
            },
          ),
        );
      } catch (e) {
        if (e is UnauthorizedException) {
          rethrow;
        }
        throw UnauthorizedException('Invalid authentication token');
      }
    };
  };
}
