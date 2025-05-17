/// DTO for chat continuation responses.
class ChatResponseDto {

  ChatResponseDto({required this.responseText});

  /// Creates a DTO instance from the generated response text.
  factory ChatResponseDto.fromDomain(String text) {
    return ChatResponseDto(responseText: text);
  }
  final String responseText;

  /// Converts the DTO instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'responseText': responseText,
      };
}