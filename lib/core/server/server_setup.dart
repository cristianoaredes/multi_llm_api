import 'package:multi_llm_api/core/config/env_config.dart';
import 'package:multi_llm_api/core/config/validation_config.dart';
import 'package:multi_llm_api/core/error/error_handler_middleware.dart';
import 'package:multi_llm_api/core/logging/log_middleware.dart';
import 'package:multi_llm_api/core/middleware/auth_middleware.dart';
import 'package:multi_llm_api/core/middleware/rate_limit_middleware.dart';
import 'package:multi_llm_api/core/middleware/sanitization_middleware.dart';
import 'package:multi_llm_api/core/middleware/validation_middleware.dart';
import 'package:multi_llm_api/features/auth/presentation/auth_handler.dart';
import 'package:multi_llm_api/features/generative/presentation/generative_handler.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';

/// Configures the main Shelf [Handler] for the server.
///
/// Sets up routers for different features, mounts them under `/api/v1`,
/// adds a health check endpoint, and applies middleware (logging, error
/// handling, authentication).
Handler setupServerHandler() {
  final log = Logger('ServerSetup')..info('Configurando servidor...');

  // Create routers for each feature
  final authRouter = AuthHandler().router;
  final generativeRouter = GenerativeHandler().router;

  // Create the main API router
  final apiRouter = Router()
    ..mount('/auth', authRouter.call) // Mount auth routes under /auth
    ..mount('/generate', generativeRouter.call);

  // Serve Swagger UI at /docs
  final swaggerHandler = SwaggerUI(
    'openapi/openapi.yaml',
    title: 'API Dart Example Docs',
  );

  // Serve static files from openapi/ at /openapi
  final staticOpenApiHandler = createStaticHandler(
    'openapi',
    defaultDocument: 'openapi.yaml',
  );

  // Define public routes (no auth needed)
  final publicRouter = Router()
    ..get('/health', (Request request) => Response.ok('OK'))
    ..mount('/docs', swaggerHandler.call) // Use .call for handlers
    ..mount('/openapi', staticOpenApiHandler); // Use handler directly

  // Get validation configuration
  final validations = ValidationConfig.getValidations();

  // Create validation middleware
  final requestValidationMiddleware = ValidationMiddleware.create(validations);

  // Create sanitization middleware
  final requestSanitizationMiddleware = SanitizationMiddleware.create();

  // Create rate limit middleware for generative AI endpoints
  final generativeRateLimitMiddleware = RateLimitMiddleware(
    requestsPerWindow: 10, // 10 requests per minute for generative endpoints
    windowDurationInSeconds: 60,
    pathPrefixes: ['/generate'], // Only apply to generative endpoints
    bypassHeaderName: EnvConfig.isDevelopment ? 'X-Rate-Limit-Bypass' : null,
    bypassHeaderValue:
        EnvConfig.isDevelopment ? 'development-bypass-key' : null,
  ).middleware;

  // Create general API rate limit middleware with higher limits
  final apiRateLimitMiddleware = RateLimitMiddleware(
    requestsPerWindow: 100, // 100 requests per minute for general API
    windowDurationInSeconds: 60,
    pathPrefixes: ['/auth'], // Apply to auth endpoints
  ).middleware;

  log.info('Middlewares configurados.');

  // Define the pipeline for authenticated API routes
  final apiPipeline = const Pipeline()
      .addMiddleware(
          requestSanitizationMiddleware) // Add sanitization middleware first
      .addMiddleware(requestValidationMiddleware) // Add validation middleware
      .addMiddleware(apiRateLimitMiddleware) // Add general API rate limiting
      .addMiddleware(
          generativeRateLimitMiddleware) // Add stricter rate limiting for generative endpoints
      .addMiddleware(authMiddleware()) // Auth applied only here
      .addHandler(apiRouter.call);

  // Combine public routes and the authenticated API routes under /api/v1
  // Use Cascade to handle routes sequentially. If a route isn't matched
  // in publicRouter, it falls through to the apiPipeline mount.
  final cascade = Cascade()
      .add(publicRouter.call) // Add public routes first
      .add((Router()..mount('/api/v1', apiPipeline))
          .call); // Add API routes under /api/v1

  log.info('Rotas configuradas.');

  // Apply global middleware (logging, error handling) to the combined handler
  final handler = const Pipeline()
      .addMiddleware(logMiddleware())
      .addMiddleware(errorHandlerMiddleware())
      .addHandler(cascade.handler); // Use the cascade handler

  log.info('Pipeline do servidor configurado com sucesso.');

  return handler;
}
