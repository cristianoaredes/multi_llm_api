import 'package:api_dart/features/auth/data/models/refresh_token.dart';
import 'package:postgres/postgres.dart';

/// Repository interface for [RefreshToken] entities.
///
/// Defines the contract for data operations on [RefreshToken] entities.
abstract class IRefreshTokenRepository {
  /// Creates a new refresh token.
  ///
  /// [userId] is the ID of the user this token belongs to.
  /// [conn] is an optional database connection for transaction support.
  /// Returns the created [RefreshToken] with its assigned ID.
  Future<RefreshToken> createToken(int userId, {Connection? conn});

  /// Finds a refresh token by its token value.
  ///
  /// [token] is the token value to search for.
  /// [conn] is an optional database connection for transaction support.
  /// Returns the [RefreshToken] with the specified token, or `null` if not found.
  Future<RefreshToken?> findByToken(String token, {Connection? conn});

  /// Finds all refresh tokens for a user.
  ///
  /// [userId] is the ID of the user to find tokens for.
  /// [conn] is an optional database connection for transaction support.
  /// Returns a list of all [RefreshToken] entities for the specified user.
  Future<List<RefreshToken>> findByUserId(int userId, {Connection? conn});

  /// Revokes a refresh token.
  ///
  /// [token] is the token value to revoke.
  /// [conn] is an optional database connection for transaction support.
  /// Returns `true` if the token was successfully revoked, `false` otherwise.
  Future<bool> revokeToken(String token, {Connection? conn});

  /// Revokes all refresh tokens for a user.
  ///
  /// [userId] is the ID of the user to revoke tokens for.
  /// [conn] is an optional database connection for transaction support.
  /// Returns the number of tokens revoked.
  Future<int> revokeAllUserTokens(int userId, {Connection? conn});

  /// Deletes expired tokens.
  ///
  /// [conn] is an optional database connection for transaction support.
  /// Returns the number of tokens deleted.
  Future<int> deleteExpiredTokens({Connection? conn});
}
