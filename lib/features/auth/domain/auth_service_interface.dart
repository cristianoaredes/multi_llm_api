import 'package:api_dart/features/auth/data/models/user.dart';

/// Interface for authentication service.
///
/// Defines the contract for authentication operations.
abstract class IAuthService {
  /// Authenticates a user with username and password.
  ///
  /// Returns a JWT token if authentication is successful.
  /// Throws [UnauthorizedException] if authentication fails.
  Future<String> login(String username, String password);

  /// Registers a new user.
  ///
  /// Returns the created [User].
  /// Throws [BadRequestException] if registration fails.
  Future<User> register(String username, String password, {String? role});

  /// Verifies a JWT token.
  ///
  /// Returns the [User] associated with the token if verification is successful.
  /// Throws [UnauthorizedException] if verification fails.
  Future<User> verifyToken(String token);

  /// Refreshes an access token using a refresh token.
  ///
  /// Returns a new JWT access token if the refresh token is valid.
  /// Throws [UnauthorizedException] if the refresh token is invalid or expired.
  Future<String> refreshToken(String refreshToken);

  /// Revokes a refresh token.
  ///
  /// Returns `true` if the token was successfully revoked, `false` otherwise.
  Future<bool> revokeToken(String refreshToken);

  /// Revokes all refresh tokens for a user.
  ///
  /// Returns the number of tokens revoked.
  Future<int> revokeAllUserTokens(int userId);

  /// Logs out a user by revoking their refresh token.
  ///
  /// Returns `true` if logout was successful, `false` otherwise.
  Future<bool> logout(String refreshToken);
}
