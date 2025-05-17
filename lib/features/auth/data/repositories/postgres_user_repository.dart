import 'package:api_dart/core/config/db_config.dart';
import 'package:api_dart/core/error/app_exception.dart';
import 'package:api_dart/features/auth/data/models/user.dart';
import 'package:api_dart/features/auth/domain/interfaces/i_user_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';
import 'dart:convert';

/// PostgreSQL implementation of the [IUserRepository].
///
/// Provides data access operations for [User] entities using a PostgreSQL database.
class PostgresUserRepository implements IUserRepository {
  /// Logger for this repository.
  final Logger _log = Logger('PostgresUserRepository');

  /// Function to get a database connection.
  /// This can be replaced in tests to provide a mock connection.
  static Future<dynamic> Function() getConnectionFn = DbConfig.getConnection;

  /// Gets a connection for database operations.
  ///
  /// If [providedConn] is not null, it will be used.
  /// Otherwise, a new connection will be obtained using [getConnectionFn].
  Future<dynamic> _getConnection(dynamic providedConn) async {
    return providedConn ?? await getConnectionFn();
  }

  @override
  Future<User?> getUserByUsername(String username) async {
    try {
      final conn = await DbConfig.getConnection();
      final results = await conn.execute(
        'SELECT id, username, password_hash, salt, role FROM users WHERE username = @username',
        parameters: {'username': username},
      );

      if (results.isEmpty) {
        return null;
      }

      final row = results.first;
      return User(
        id: row[0] as int,
        username: row[1] as String,
        passwordHash: row[2] as String,
        salt: row[3] as String,
        role: row[4] as String,
      );
    } catch (e, stackTrace) {
      _log.severe('Failed to get user by username: $username', e, stackTrace);
      throw InternalServerException('Database error while retrieving user');
    }
  }

  @override
  Future<User?> getUserById(int id, {Connection? conn}) async {
    try {
      final connection = await _getConnection(conn);
      final results = await connection.execute(
        'SELECT id, username, password_hash, salt, role FROM users WHERE id = @id',
        parameters: {'id': id},
      );

      if (results is Iterable) {
        if (results.isEmpty) {
          return null;
        }

        if (results.isNotEmpty) {
          final row = results.first;
          if (row is List) {
            return User(
              id: row[0] as int,
              username: row[1] as String,
              passwordHash: row[2] as String,
              salt: row[3] as String,
              role: row[4] as String,
            );
          }
        }
      }
      
      return null;
    } catch (e, stackTrace) {
      _log.severe('Failed to get user by ID: $id', e, stackTrace);
      throw InternalServerException('Database error while retrieving user');
    }
  }

  @override
  Future<User> createUser(
    String username,
    String passwordHash,
    String salt,
    String role,
  ) async {
    try {
      // Check if username already exists
      final existingUser = await getUserByUsername(username);
      if (existingUser != null) {
        throw BadRequestException('Username already exists');
      }

      final conn = await DbConfig.getConnection();
      final results = await conn.execute(
        '''
        INSERT INTO users (username, password_hash, salt, role)
        VALUES (@username, @password_hash, @salt, @role)
        RETURNING id, username, password_hash, salt, role
        ''',
        parameters: {
          'username': username,
          'password_hash': passwordHash,
          'salt': salt,
          'role': role,
        },
      );

      final row = results.first;
      return User(
        id: row[0] as int,
        username: row[1] as String,
        passwordHash: row[2] as String,
        salt: row[3] as String,
        role: row[4] as String,
      );
    } catch (e, stackTrace) {
      if (e is BadRequestException) {
        rethrow;
      }
      _log.severe('Failed to create user', e, stackTrace);
      throw InternalServerException('Database error while creating user');
    }
  }

  @override
  Future<User?> verifyCredentials(String username, String password) async {
    try {
      // Get user by username
      final user = await getUserByUsername(username);
      if (user == null) {
        return null;
      }

      // Hash the provided password with the stored salt
      final hashedPassword = _hashPassword(password, user.salt);

      // Compare the hashed password with the stored hash
      if (hashedPassword == user.passwordHash) {
        return user;
      }

      return null;
    } catch (e, stackTrace) {
      _log.severe('Failed to verify credentials', e, stackTrace);
      throw InternalServerException('Error while verifying credentials');
    }
  }

  @override
  Future<bool> updatePassword(
    int userId,
    String newPasswordHash,
    String newSalt,
  ) async {
    try {
      final conn = await DbConfig.getConnection();
      final result = await conn.execute(
        '''
        UPDATE users
        SET password_hash = @password_hash, salt = @salt, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        ''',
        parameters: {
          'id': userId,
          'password_hash': newPasswordHash,
          'salt': newSalt,
        },
      );

      return result.affectedRows > 0;
    } catch (e, stackTrace) {
      _log.severe('Failed to update password for user ID: $userId', e, stackTrace);
      throw InternalServerException('Database error while updating password');
    }
  }

  @override
  Future<bool> deleteUser(int userId) async {
    try {
      final conn = await DbConfig.getConnection();
      final result = await conn.execute(
        'DELETE FROM users WHERE id = @id',
        parameters: {'id': userId},
      );

      return result.affectedRows > 0;
    } catch (e, stackTrace) {
      _log.severe('Failed to delete user with ID: $userId', e, stackTrace);
      throw InternalServerException('Database error while deleting user');
    }
  }

  /// Hashes a password with the given salt using SHA-256.
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
