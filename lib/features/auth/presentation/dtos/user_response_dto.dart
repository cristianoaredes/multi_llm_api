import 'package:api_dart/features/auth/data/models/user.dart';

/// {@template user_response_dto}
/// Data Transfer Object for user responses.
///
/// Contains user information to be returned in API responses.
/// {@endtemplate}
class UserResponseDto {
  /// {@macro user_response_dto}
  UserResponseDto({
    required this.id,
    required this.username,
    required this.role,
  });

  /// Creates a [UserResponseDto] from a domain [User] model.
  factory UserResponseDto.fromDomain(User user) {
    return UserResponseDto(
      id: user.id,
      username: user.username,
      role: user.role,
    );
  }

  /// The user's ID.
  final int id;
  
  /// The user's username.
  final String username;
  
  /// The user's role.
  final String role;

  /// Converts the DTO to a JSON encodable Map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'role': role,
  };
}
