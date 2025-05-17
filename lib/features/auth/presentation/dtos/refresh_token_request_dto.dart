/// {@template refresh_token_request_dto}
/// Data Transfer Object for refresh token requests.
///
/// Used to request a new access token using a refresh token.
/// {@endtemplate}
class RefreshTokenRequestDto {
  /// {@macro refresh_token_request_dto}
  RefreshTokenRequestDto({
    required this.refreshToken,
  });

  /// Creates a [RefreshTokenRequestDto] from a JSON object.
  factory RefreshTokenRequestDto.fromJson(Map<String, dynamic> json) {
    final refreshToken = json['refreshToken'] as String?;
    
    if (refreshToken == null || refreshToken.isEmpty) {
      throw FormatException('Refresh token is required');
    }
    
    return RefreshTokenRequestDto(
      refreshToken: refreshToken,
    );
  }

  /// The refresh token.
  final String refreshToken;

  /// Converts this DTO to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}
