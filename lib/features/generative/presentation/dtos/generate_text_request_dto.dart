import 'package:multi_llm_api/core/error/app_exception.dart'; // Use package import

/// {@template generate_text_request_dto}
/// Data Transfer Object for text generation request payloads.
/// {@endtemplate}
class GenerateTextRequestDto {
  /// {@macro generate_text_request_dto}
  GenerateTextRequestDto({required this.prompt});

  /// Creates a [GenerateTextRequestDto] from JSON, validating the prompt field.
  factory GenerateTextRequestDto.fromJson(Map<String, dynamic> json) {
    final prompt = json['prompt'] as String?;

    if (prompt == null || prompt.trim().isEmpty) {
      // Ensure formatting and comma
      throw BadRequestException(
        "Field 'prompt' is required and cannot be empty.",);
    }

    // Add any other prompt validation if needed (e.g., length limits)

    return GenerateTextRequestDto(prompt: prompt);
  }

  /// The prompt used for text generation.
  final String prompt;
}
