import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart' show Level;

/// Environment types supported by the application.
enum Environment {
  /// Development environment for local development.
  development,

  /// Testing environment for automated tests.
  test,

  /// Production environment for deployed applications.
  production,
}

/// Configuration class that manages environment variables.
class EnvConfig {
  // Private instance of DotEnv for use in methods
  static final _dotenv = DotEnv();

  // Current environment
  static late Environment _environment;

  /// Gets the current environment.
  static Environment get environment => _environment;

  /// Loads environment variables from the appropriate .env file based on the environment.
  static Future<void> loadEnv({Environment? env, bool logOutput = true}) async {
    // If an environment is provided, use it; otherwise, determine from DART_ENV
    _environment = env ?? _determineEnvironment();

    if (logOutput) {
      print('Environment: ${_environment.name}');
    }

    // Try to load from environment-specific file first
    final envFileName = _getEnvFileName(_environment);
    try {
      _dotenv.load([envFileName]);
      if (logOutput) {
        print('Loaded environment file: $envFileName');
      }
    } catch (e) {
      // If environment-specific file fails, try to load from .env
      try {
        _dotenv.load(['.env']);
        if (logOutput) {
          print('Loaded default .env file');
        }
      } catch (e) {
        // Swallow error if .env also doesn't exist - we'll use defaults
        if (logOutput) {
          print('Warning: No environment file found, using defaults');
        }
      }
    }
  }

  /// Determines the current environment based on the DART_ENV environment variable.
  static Environment _determineEnvironment() {
    final envName =
        Platform.environment['DART_ENV']?.toLowerCase() ?? 'development';

    if (envName == 'production') {
      return Environment.production;
    } else if (envName == 'test') {
      return Environment.test;
    } else {
      return Environment.development;
    }
  }

  /// Gets the environment file name based on the environment.
  static String _getEnvFileName(Environment env) {
    switch (env) {
      case Environment.production:
        return '.env.production';
      case Environment.test:
        return '.env.test';
      case Environment.development:
        return '.env.development';
    }
  }

  /// Gets the server port from environment variables
  static int get serverPort {
    return int.tryParse(_dotenv['SERVER_PORT'] ?? '8080') ?? 8080;
  }

  /// Gets the log level from environment variables
  static Level get logLevel {
    final levelName = _dotenv['LOG_LEVEL'] ?? 'INFO';
    return Level.LEVELS.firstWhere(
      (level) => level.name == levelName.toUpperCase(),
      orElse: () => Level.INFO,
    );
  }

  /// Gets the Gemini API key from environment variables
  static String get geminiApiKey {
    final key = _dotenv['GEMINI_API_KEY'];
    if (key == null || key.isEmpty || key == 'YOUR_API_KEY_HERE') {
      throw StateError(
        'GEMINI_API_KEY is not defined or has default value in the '
        '.env file.',
      );
    }
    return key;
  }

  /// Gets the Gemini model name from environment variables
  static String get geminiModel {
    return _dotenv['GEMINI_MODEL'] ?? 'gemini-1.5-flash-latest';
  }

  /// Gets the Gemini max tokens from environment variables
  static int get geminiMaxTokens {
    return int.tryParse(_dotenv['GEMINI_MAX_TOKENS'] ?? '2048') ?? 2048;
  }

  /// Gets the Gemini temperature from environment variables
  static double get geminiTemperature {
    return double.tryParse(_dotenv['GEMINI_TEMPERATURE'] ?? '0.7') ?? 0.7;
  }

  /// Gets the Gemini safety settings threshold for harassment category
  static String get geminiSafetyHarassment {
    return _dotenv['GEMINI_SAFETY_HARASSMENT'] ?? 'BLOCK_MEDIUM_AND_ABOVE';
  }

  /// Gets the Gemini safety settings threshold for hate speech category
  static String get geminiSafetyHateSpeech {
    return _dotenv['GEMINI_SAFETY_HATE_SPEECH'] ?? 'BLOCK_MEDIUM_AND_ABOVE';
  }

  /// Gets the Gemini safety settings threshold for sexually explicit content
  static String get geminiSafetySexuallyExplicit {
    return _dotenv['GEMINI_SAFETY_SEXUALLY_EXPLICIT'] ??
        'BLOCK_MEDIUM_AND_ABOVE';
  }

  /// Gets the Gemini safety settings threshold for dangerous content
  static String get geminiSafetyDangerous {
    return _dotenv['GEMINI_SAFETY_DANGEROUS'] ?? 'BLOCK_MEDIUM_AND_ABOVE';
  }

  /// Gets whether streaming responses are enabled for Gemini
  static bool get geminiEnableStreaming {
    return _dotenv['GEMINI_ENABLE_STREAMING']?.toLowerCase() == 'true';
  }

  /// Gets the AI provider to use (gemini or openrouter)
  static String get aiProvider {
    return _dotenv['AI_PROVIDER']?.toLowerCase() ?? 'gemini';
  }

  /// Gets the OpenRouter API key from environment variables
  /// Returns empty string if not defined (which will put OpenRouter service in simulation mode)
  static String get openRouterApiKey {
    final key = _dotenv['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty || key == 'YOUR_API_KEY_HERE') {
      return '';
    }
    return key;
  }

  /// Gets the OpenRouter base URL from environment variables
  static String get openRouterBaseUrl {
    return _dotenv['OPENROUTER_BASE_URL'] ?? 'https://openrouter.ai/api/v1';
  }

  /// Gets the OpenRouter model name from environment variables
  static String get openRouterModel {
    return _dotenv['OPENROUTER_MODEL'] ?? 'openai/gpt-3.5-turbo';
  }

  /// Gets the OpenRouter max tokens from environment variables
  static int get openRouterMaxTokens {
    return int.tryParse(_dotenv['OPENROUTER_MAX_TOKENS'] ?? '2048') ?? 2048;
  }

  /// Gets the OpenRouter temperature from environment variables
  static double get openRouterTemperature {
    return double.tryParse(_dotenv['OPENROUTER_TEMPERATURE'] ?? '0.7') ?? 0.7;
  }

  /// Gets whether streaming responses are enabled for OpenRouter
  static bool get openRouterEnableStreaming {
    return _dotenv['OPENROUTER_ENABLE_STREAMING']?.toLowerCase() == 'true';
  }

  /// Gets the database host from environment variables
  static String get dbHost {
    return _dotenv['DB_HOST'] ?? 'localhost';
  }

  /// Gets the database port from environment variables
  static int get dbPort {
    return int.tryParse(_dotenv['DB_PORT'] ?? '5432') ?? 5432;
  }

  /// Gets the database name from environment variables
  static String get dbName {
    return _dotenv['DB_NAME'] ?? 'api_dart';
  }

  /// Gets the database username from environment variables
  static String get dbUsername {
    return _dotenv['DB_USERNAME'] ?? 'postgres';
  }

  /// Gets the database password from environment variables
  static String get dbPassword {
    return _dotenv['DB_PASSWORD'] ?? 'postgres';
  }

  /// Gets whether to use SSL for database connection
  static bool get dbUseSSL {
    return _dotenv['DB_USE_SSL']?.toLowerCase() == 'true';
  }

  /// Gets the JWT secret key from environment variables
  static String get jwtSecret {
    final secret = _dotenv['JWT_SECRET'];
    if (secret == null || secret.isEmpty || secret == 'YOUR_SECRET_KEY_HERE') {
      throw StateError(
        'JWT_SECRET is not defined or has default value in the '
        '.env file.',
      );
    }
    return secret;
  }

  /// Gets the JWT token expiration time in hours
  static int get jwtExpirationHours {
    return int.tryParse(_dotenv['JWT_EXPIRATION_HOURS'] ?? '24') ?? 24;
  }

  /// Gets the allowed CORS origins from environment variables
  static List<String> get corsAllowedOrigins {
    final origins = _dotenv['CORS_ALLOWED_ORIGINS'] ?? '';
    if (origins.isEmpty) {
      return [];
    }
    return origins.split(',').map((origin) => origin.trim()).toList();
  }

  /// Gets whether to allow credentials for CORS
  static bool get corsAllowCredentials {
    return _dotenv['CORS_ALLOW_CREDENTIALS']?.toLowerCase() == 'true';
  }

  /// Checks if the current environment is production
  static bool get isProduction => _environment == Environment.production;

  /// Checks if the current environment is development
  static bool get isDevelopment => _environment == Environment.development;

  /// Checks if the current environment is test
  static bool get isTest => _environment == Environment.test;
}
