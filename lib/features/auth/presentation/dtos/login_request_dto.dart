import 'package:multi_llm_api/core/error/app_exception.dart';

/// {@template login_request_dto}
/// Data Transfer Object for login request payloads.
///
/// Contains user credentials and validation logic.
/// {@endtemplate}
class LoginRequestDto {
  /// {@macro login_request_dto}
  LoginRequestDto({required this.username, required this.password});

  /// Creates a [LoginRequestDto] from JSON, validating required fields.
  factory LoginRequestDto.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String?;
    final password = json['password'] as String?;

    if (username == null || username.isEmpty) {
      throw BadRequestException(
          "Field 'username' is required and cannot be empty.",); // Add comma
    }
    if (password == null || password.isEmpty) {
      // In a real app, you might have password complexity rules here too
      throw BadRequestException(
          "Field 'password' is required and cannot be empty.",); // Add comma
    }

    return LoginRequestDto(
      username: username,
      password: password,
    );
  }
  /// The username provided for login.
  final String username;
  /// The password provided for login.
  final String password;
}
