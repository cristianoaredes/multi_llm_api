/// Data Transfer Object for the login response.
class LoginResponseDto {
  /// Creates a login response DTO.
  LoginResponseDto({required this.token});

  /// The authentication token.
  final String token;

  /// Converts the DTO to a JSON encodable Map.
  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}
