import 'dart:io';
import 'package:multi_llm_api/core/config/db_config.dart';
import 'package:multi_llm_api/core/config/env_config.dart';
import 'package:multi_llm_api/core/di/injector.dart';
import 'package:multi_llm_api/core/logging/log_config.dart';
import 'package:multi_llm_api/core/server/server_setup.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main(List<String> args) async {
  // Parse command line arguments
  Environment? env;
  int? customPort;

  // Process command-line arguments
  for (final arg in args) {
    // Environment arguments
    if (arg == '--env=production' || arg == '-p') {
      env = Environment.production;
    } else if (arg == '--env=test' || arg == '-t') {
      env = Environment.test;
    } else if (arg == '--env=development' || arg == '-d') {
      env = Environment.development;
    }
    // Port argument
    else if (arg.startsWith('--port=')) {
      final portStr = arg.substring('--port='.length);
      customPort = int.tryParse(portStr);
    }
  }

  // Load environment variables
  await EnvConfig.loadEnv(env: env);

  // Setup logging
  setupLogging();
  final log = Logger('Server');

  log.info('Starting server in ${EnvConfig.environment.name} environment');

  // Setup dependency injection
  await setupInjector();
  log.info('Dependency injector initialized.');

  // Initialize database
  try {
    await DbConfig.initializeDatabase();
    log.info('Database initialized successfully.');
  } catch (e, stackTrace) {
    log.severe('Failed to initialize database', e, stackTrace);

    if (EnvConfig.isProduction) {
      log.severe('Exiting: Database connection is required in production');
      exit(1);
    } else {
      log.warning('Server will start with in-memory repositories as fallback.');
    }
  }

  // Setup server handler (routes, middleware)
  final handler = setupServerHandler();

  // Get server port with priority:
  // 1. Command line argument
  // 2. Environment config
  final port = customPort ?? EnvConfig.serverPort;

  // Log if a custom port is being used
  if (customPort != null) {
    log.info('Using custom port from command line argument: $port');
  }

  final server =
      await io.serve(handler, '0.0.0.0', port); // Listen on all interfaces

  log.info('Server listening on port ${server.port}');

  // Add CORS headers based on environment configuration
  if (EnvConfig.corsAllowedOrigins.isNotEmpty) {
    if (EnvConfig.corsAllowedOrigins.length == 1) {
      server.defaultResponseHeaders.add(
        'Access-Control-Allow-Origin',
        EnvConfig.corsAllowedOrigins.first,
      );
    } else {
      // For multiple origins, we'll need to handle this in middleware
      // as the origin needs to be checked against the request
      log.info(
          'Multiple CORS origins configured. Using middleware for CORS handling.');
    }

    server.defaultResponseHeaders.add(
      'Access-Control-Allow-Methods',
      'GET, POST, PUT, DELETE, OPTIONS',
    );
    server.defaultResponseHeaders.add(
      'Access-Control-Allow-Headers',
      'Origin, Content-Type, Authorization',
    );

    if (EnvConfig.corsAllowCredentials) {
      server.defaultResponseHeaders.add(
        'Access-Control-Allow-Credentials',
        'true',
      );
    }
  }

  log.info('Server started. Press Ctrl+C to stop.');
}
