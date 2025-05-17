import 'package:multi_llm_api/core/middleware/validation_middleware.dart';
import 'package:multi_llm_api/features/auth/presentation/dtos/login_request_dto.dart';
import 'package:multi_llm_api/features/auth/presentation/dtos/refresh_token_request_dto.dart';
import 'package:multi_llm_api/features/auth/presentation/dtos/register_request_dto.dart';
import 'package:multi_llm_api/features/generative/presentation/dtos/chat_request_dto.dart';
import 'package:multi_llm_api/features/generative/presentation/dtos/generate_text_request_dto.dart';

/// Configuration for request validation.
///
/// This class provides a centralized configuration for request validation
/// across the application. It defines validation functions for different
/// endpoints and HTTP methods.
class ValidationConfig {
  // Private constructor to prevent instantiation
  ValidationConfig._();

  /// Gets the validation configuration for the application.
  ///
  /// Returns a map where keys are request paths and values are maps
  /// of HTTP methods to validation functions.
  static Map<String, Map<String, ValidationFunction>> getValidations() {
    return {
      // Auth endpoints
      '/api/v1/auth/login': {
        'POST': LoginRequestDto.fromJson,
      },
      '/api/v1/auth/register': {
        'POST': RegisterRequestDto.fromJson,
      },
      '/api/v1/auth/refresh': {
        'POST': RefreshTokenRequestDto.fromJson,
      },
      '/api/v1/auth/logout': {
        'POST': RefreshTokenRequestDto.fromJson,
      },

      // Generative endpoints
      '/api/v1/generate/text': {
        'POST': GenerateTextRequestDto.fromJson,
      },
      '/api/v1/generate/text/stream': {
        'POST': GenerateTextRequestDto.fromJson,
      },
      '/api/v1/generate/chat': {
        'POST': ChatRequestDto.fromJson,
      },
      '/api/v1/generate/chat/stream': {
        'POST': ChatRequestDto.fromJson,
      },
      '/api/v1/generate/models': {
        // Endpoint GET não requer validação, pois não tem corpo
      },
    };
  }
}
