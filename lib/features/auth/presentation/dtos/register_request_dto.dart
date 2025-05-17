import 'package:multi_llm_api/core/error/app_exception.dart';

/// {@template register_request_dto}
/// Data Transfer Object for registration request payloads.
///
/// Contains user registration data and validation logic.
/// {@endtemplate}
class RegisterRequestDto {
  /// {@macro register_request_dto}
  RegisterRequestDto({
    required this.username,
    required this.password,
    this.role,
  });

  /// Creates a [RegisterRequestDto] from JSON, validating required fields.
  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String?;
    final password = json['password'] as String?;
    final role = json['role'] as String?;

    if (username == null || username.isEmpty) {
      throw BadRequestException(
        "Field 'username' is required and cannot be empty.",
      );
    }
    
    if (password == null || password.isEmpty) {
      throw BadRequestException(
        "Field 'password' is required and cannot be empty.",
      );
    }
    
    // Validate password complexity
    if (password.length < 8) {
      throw BadRequestException(
        "Password must be at least 8 characters long.",
      );
    }
    
    // Validate username format
    if (username.length < 3) {
      throw BadRequestException(
        "Username must be at least 3 characters long.",
      );
    }
    
    // Validate role if provided
    if (role != null && role != 'user' && role != 'admin') {
      throw BadRequestException(
        "Role must be either 'user' or 'admin'.",
      );
    }

    return RegisterRequestDto(
      username: username,
      password: password,
      role: role,
    );
  }
  
  /// The username for registration.
  final String username;
  
  /// The password for registration.
  final String password;
  
  /// The role for the new user (optional).
  final String? role;
}
