# Environment Configuration Guide

This document explains how to configure different environments in the API Dart project.

## Overview

The API Dart project supports multiple environments:

- **Development**: For local development
- **Test**: For automated testing
- **Production**: For deployed applications

Each environment has its own configuration file, which allows for different settings in different environments.

## Environment Files

The project uses the following environment files:

- `.env.development`: Configuration for local development
- `.env.test`: Configuration for automated testing
- `.env.production`: Configuration for production deployment
- `.env`: Fallback configuration (optional)

## Environment Variables

The following environment variables are supported:

### Server Configuration

- `SERVER_PORT`: The port on which the server will listen
- `LOG_LEVEL`: The logging level (ALL, FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, SHOUT, OFF)

### Gemini AI Configuration

- `GEMINI_API_KEY`: API key for the Gemini AI service
- `GEMINI_MODEL`: The Gemini model to use (e.g., gemini-1.5-flash-latest, gemini-1.5-pro-latest)
- `GEMINI_MAX_TOKENS`: Maximum number of tokens for generation
- `GEMINI_TEMPERATURE`: Temperature parameter for generation (0.0 to 1.0)

### Database Configuration

- `DB_HOST`: Database host
- `DB_PORT`: Database port
- `DB_NAME`: Database name
- `DB_USERNAME`: Database username
- `DB_PASSWORD`: Database password
- `DB_USE_SSL`: Whether to use SSL for database connection (true/false)

### JWT Configuration

- `JWT_SECRET`: Secret key for JWT token generation
- `JWT_EXPIRATION_HOURS`: JWT token expiration time in hours

### CORS Configuration

- `CORS_ALLOWED_ORIGINS`: Comma-separated list of allowed origins
- `CORS_ALLOW_CREDENTIALS`: Whether to allow credentials (true/false)

## Setting the Environment

You can set the environment in several ways:

### 1. Command Line Arguments

When starting the server, you can specify the environment using command line arguments:

```bash
# Development environment
dart run bin/server.dart --env=development
# or
dart run bin/server.dart -d

# Test environment
dart run bin/server.dart --env=test
# or
dart run bin/server.dart -t

# Production environment
dart run bin/server.dart --env=production
# or
dart run bin/server.dart -p
```

### 2. Environment Variable

You can set the `DART_ENV` environment variable:

```bash
# Linux/macOS
export DART_ENV=production
dart run bin/server.dart

# Windows
set DART_ENV=production
dart run bin/server.dart
```

### 3. Default Environment

If no environment is specified, the server will default to the development environment.

## Environment-Specific Behavior

The application behavior changes based on the environment:

### Development Environment

- Detailed logging
- In-memory repositories as fallback if database connection fails
- CORS configured for local development

### Test Environment

- Deterministic behavior for testing (e.g., zero temperature for AI)
- Short token expiration
- In-memory repositories as fallback

### Production Environment

- Minimal logging (warnings and errors only)
- Strict database connection requirement (server exits if connection fails)
- More capable AI model
- Stricter security settings

## Accessing Environment Configuration in Code

The `EnvConfig` class provides access to environment variables and environment-specific behavior:

```dart
import 'package:api_dart/core/config/env_config.dart';

// Get the current environment
final env = EnvConfig.environment;

// Check the environment
if (EnvConfig.isProduction) {
  // Production-specific code
} else if (EnvConfig.isDevelopment) {
  // Development-specific code
} else if (EnvConfig.isTest) {
  // Test-specific code
}

// Access environment variables
final port = EnvConfig.serverPort;
final logLevel = EnvConfig.logLevel;
final dbHost = EnvConfig.dbHost;
// etc.
```

## Best Practices

1. **Never commit sensitive information** (API keys, passwords, etc.) to version control. Use environment variables or `.env` files that are excluded from version control.

2. **Use environment-specific settings** for different environments. For example, use a more capable AI model in production, but a faster model in development.

3. **Be strict in production**. In production, fail fast if required resources are not available. In development, provide fallbacks where possible.

4. **Use different database names** for different environments to avoid data corruption.

5. **Document environment variables** in this file when adding new ones.
