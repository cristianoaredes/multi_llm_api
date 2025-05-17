import 'package:multi_llm_api/core/error/app_exception.dart';

/// DTO for chat continuation requests.
class ChatRequestDto {

  ChatRequestDto({required this.history, required this.newMessage});

  /// Creates a DTO instance from a JSON map.
  ///
  /// Performs basic validation.
  factory ChatRequestDto.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['history'];
    final newMessage = json['newMessage'] as String?;

    if (newMessage == null || newMessage.trim().isEmpty) {
      throw BadRequestException("Field 'newMessage' is required and cannot be empty.");
    }

    if (historyRaw == null || historyRaw is! List) {
       throw BadRequestException("Field 'history' is required and must be a list.");
    }

    // Validate history format
    final history = <Map<String, String>>[];
    try {
       for (final item in historyRaw) {
         if (item is! Map<String, dynamic>) {
           throw const FormatException('History item is not a map.');
         }
         final role = item['role'] as String?;
         final text = item['text'] as String?;
         if (role == null || text == null || (role != 'user' && role != 'model')) {
            throw const FormatException('Invalid role or text in history item.');
         }
         history.add({'role': role, 'text': text});
       }
    } catch (e) {
       throw BadRequestException('Invalid format for chat history: $e');
    }


    return ChatRequestDto(history: history, newMessage: newMessage);
  }
  final List<Map<String, String>> history;
  final String newMessage;

  // toJson might not be needed for request DTOs, but can be useful for logging/debugging
  Map<String, dynamic> toJson() => {
        'history': history,
        'newMessage': newMessage,
      };
}