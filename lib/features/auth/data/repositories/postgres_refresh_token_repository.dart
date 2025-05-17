import 'package:multi_llm_api/core/config/db_config.dart';
import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:multi_llm_api/features/auth/data/models/refresh_token.dart';
import 'package:multi_llm_api/features/auth/domain/interfaces/i_refresh_token_repository.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';

/// PostgreSQL implementation of the [IRefreshTokenRepository].
///
/// Provides data access operations for [RefreshToken] entities using a PostgreSQL database.
class PostgresRefreshTokenRepository implements IRefreshTokenRepository {
  /// Logger for this repository.
  final Logger _log = Logger('PostgresRefreshTokenRepository');
  
  /// Function to get a database connection.
  /// This can be replaced in tests to provide a mock connection.
  static Future<dynamic> Function() getConnectionFn = DbConfig.getConnection;

  /// Creates a new [RefreshToken] from a PostgreSQL result row.
  ///
  /// Converts a database row to a [RefreshToken] entity.
  RefreshToken _tokenFromRow(List<dynamic> row) {
    return RefreshToken(
      id: row[0] as int,
      userId: row[1] as int,
      token: row[2] as String,
      expiresAt: row[3] as DateTime,
      isRevoked: row[4] as bool,
    );
  }

  /// Gets a connection for database operations.
  ///
  /// If [providedConn] is not null, it will be used.
  /// Otherwise, a new connection will be obtained using [getConnectionFn].
  Future<dynamic> _getConnection(dynamic providedConn) async {
    return providedConn ?? await getConnectionFn();
  }

  @override
  Future<RefreshToken> createToken(int userId, {Connection? conn}) async {
    try {
      final connection = await _getConnection(conn);
      
      // Generate a new refresh token
      final refreshToken = RefreshToken.generate(userId);
      
      final results = await connection.execute(
        'INSERT INTO refresh_tokens (user_id, token, expires_at, is_revoked) '
        'VALUES (@userId, @token, @expiresAt, @isRevoked) '
        'RETURNING id, user_id, token, expires_at, is_revoked',
        parameters: {
          'userId': userId,
          'token': refreshToken.token,
          'expiresAt': refreshToken.expiresAt,
          'isRevoked': false,
        },
      );

      if (results is Iterable) {
        if (results.isNotEmpty) {
          final firstRow = results.first;
          if (firstRow is List) {
            return _tokenFromRow(firstRow);
          }
        }
      }
      
      throw InternalServerException('Failed to create refresh token: unexpected result format');
    } catch (e, stackTrace) {
      _log.severe('Failed to create refresh token', e, stackTrace);
      throw InternalServerException('Database error while creating refresh token');
    }
  }

  @override
  Future<RefreshToken?> findByToken(String token, {Connection? conn}) async {
    try {
      final connection = await _getConnection(conn);
      final results = await connection.execute(
        'SELECT id, user_id, token, expires_at, is_revoked '
        'FROM refresh_tokens WHERE token = @token',
        parameters: {'token': token},
      );

      if (results is Iterable) {
        if (results.isEmpty) {
          return null;
        }

        if (results.isNotEmpty) {
          final firstRow = results.first;
          if (firstRow is List) {
            return _tokenFromRow(firstRow);
          }
        }
      }
      
      return null;
    } catch (e, stackTrace) {
      _log.severe('Failed to find refresh token', e, stackTrace);
      throw InternalServerException('Database error while finding refresh token');
    }
  }

  @override
  Future<List<RefreshToken>> findByUserId(int userId, {Connection? conn}) async {
    try {
      final connection = await _getConnection(conn);
      final results = await connection.execute(
        'SELECT id, user_id, token, expires_at, is_revoked '
        'FROM refresh_tokens WHERE user_id = @userId',
        parameters: {'userId': userId},
      );

      final tokens = <RefreshToken>[];
      if (results is Iterable) {
        for (final row in results) {
          if (row is List) {
            tokens.add(_tokenFromRow(row));
          }
        }
      }
      return tokens;
    } catch (e, stackTrace) {
      _log.severe('Failed to find refresh tokens for user', e, stackTrace);
      throw InternalServerException('Database error while finding refresh tokens');
    }
  }

  @override
  Future<bool> revokeToken(String token, {Connection? conn}) async {
    try {
      final connection = await _getConnection(conn);
      final result = await connection.execute(
        'UPDATE refresh_tokens SET is_revoked = true '
        'WHERE token = @token AND is_revoked = false',
        parameters: {'token': token},
      );

      // Check if any rows were affected
      if (result != null) {
        if (result.affectedRows is int) {
          return (result.affectedRows as int) > 0;
        }
      }
      
      // Fallback if affectedRows is not available
      final tokenAfterRevoke = await findByToken(token, conn: conn);
      return tokenAfterRevoke != null && tokenAfterRevoke.isRevoked;
    } catch (e, stackTrace) {
      _log.severe('Failed to revoke refresh token', e, stackTrace);
      throw InternalServerException('Database error while revoking refresh token');
    }
  }

  @override
  Future<int> revokeAllUserTokens(int userId, {Connection? conn}) async {
    try {
      final connection = await _getConnection(conn);
      final result = await connection.execute(
        'UPDATE refresh_tokens SET is_revoked = true '
        'WHERE user_id = @userId AND is_revoked = false',
        parameters: {'userId': userId},
      );

      // Check if any rows were affected
      if (result != null) {
        if (result.affectedRows is int) {
          return result.affectedRows as int;
        }
      }
      
      // Fallback if affectedRows is not available
      return 0;
    } catch (e, stackTrace) {
      _log.severe('Failed to revoke all user refresh tokens', e, stackTrace);
      throw InternalServerException('Database error while revoking refresh tokens');
    }
  }

  @override
  Future<int> deleteExpiredTokens({Connection? conn}) async {
    try {
      final connection = await _getConnection(conn);
      final result = await connection.execute(
        'DELETE FROM refresh_tokens WHERE expires_at < CURRENT_TIMESTAMP',
      );

      // Check if any rows were affected
      if (result != null) {
        if (result.affectedRows is int) {
          return result.affectedRows as int;
        }
      }
      
      // Fallback if affectedRows is not available
      return 0;
    } catch (e, stackTrace) {
      _log.severe('Failed to delete expired refresh tokens', e, stackTrace);
      throw InternalServerException('Database error while deleting expired tokens');
    }
  }
}
