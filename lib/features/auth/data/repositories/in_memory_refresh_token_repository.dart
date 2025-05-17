import 'package:multi_llm_api/features/auth/data/models/refresh_token.dart';
import 'package:multi_llm_api/features/auth/domain/interfaces/i_refresh_token_repository.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';

/// In-memory implementation of [IRefreshTokenRepository].
///
/// This implementation stores refresh tokens in memory and is intended for
/// development and testing purposes only.
class InMemoryRefreshTokenRepository implements IRefreshTokenRepository {
  final Logger _log = Logger('InMemoryRefreshTokenRepository');
  final Map<int, RefreshToken> _tokens = {};
  int _nextId = 1;

  @override
  Future<RefreshToken> createToken(int userId, {Connection? conn}) async {
    _log.info('Creating refresh token for user: $userId');

    // Generate a new token
    final token = RefreshToken.generate(userId);

    // Assign an ID and store the token
    final storedToken = token.copyWith(id: _nextId++);
    _tokens[storedToken.id] = storedToken;

    return storedToken;
  }

  @override
  Future<RefreshToken?> findByToken(String token, {Connection? conn}) async {
    _log.info('Finding refresh token: $token');

    try {
      return _tokens.values.firstWhere(
        (t) => t.token == token,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<RefreshToken>> findByUserId(int userId, {Connection? conn}) async {
    _log.info('Finding refresh tokens for user: $userId');

    return _tokens.values.where((token) => token.userId == userId).toList();
  }

  @override
  Future<bool> revokeToken(String token, {Connection? conn}) async {
    _log.info('Revoking refresh token: $token');

    try {
      final refreshToken = _tokens.values.firstWhere(
        (t) => t.token == token,
      );

      // Create a new token with isRevoked set to true
      final revokedToken = refreshToken.copyWith(isRevoked: true);

      // Store the revoked token
      _tokens[revokedToken.id] = revokedToken;

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> revokeAllUserTokens(int userId, {Connection? conn}) async {
    _log.info('Revoking all refresh tokens for user: $userId');

    final userTokens = _tokens.values.where((token) => token.userId == userId).toList();

    for (final token in userTokens) {
      // Create a new token with isRevoked set to true
      final revokedToken = token.copyWith(isRevoked: true);

      // Store the revoked token
      _tokens[revokedToken.id] = revokedToken;
    }

    return userTokens.length;
  }

  @override
  Future<int> deleteExpiredTokens({Connection? conn}) async {
    _log.info('Deleting expired refresh tokens');

    final now = DateTime.now();
    final expiredTokens = _tokens.values.where((token) => token.expiresAt.isBefore(now)).toList();

    for (final token in expiredTokens) {
      _tokens.remove(token.id);
    }

    return expiredTokens.length;
  }
}
