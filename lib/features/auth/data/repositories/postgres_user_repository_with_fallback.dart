import 'package:multi_llm_api/core/config/db_config.dart';
import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:multi_llm_api/features/auth/data/models/user.dart';
import 'package:multi_llm_api/features/auth/data/repositories/in_memory_user_repository.dart';
import 'package:multi_llm_api/features/auth/domain/interfaces/i_user_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';
import 'dart:convert';

/// PostgreSQL implementation of the [IUserRepository] with in-memory fallback.
///
/// Provides data access operations for [User] entities using a PostgreSQL database.
/// Falls back to an in-memory repository if the database is not available.
class PostgresUserRepositoryWithFallback implements IUserRepository {
  /// Logger for this repository.
  final Logger _log = Logger('PostgresUserRepositoryWithFallback');

  /// In-memory repository to use as a fallback.
  final InMemoryUserRepository _fallbackRepository = InMemoryUserRepository();

  /// Function to get a database connection.
  /// This can be replaced in tests to provide a mock connection.
  static Future<dynamic> Function() getConnectionFn = DbConfig.getConnection;

  @override
  Future<User?> getUserByUsername(String username) async {
    try {
      final conn = await getConnectionFn();
      final results = await conn.execute(
        'SELECT id, username, password_hash, salt, role FROM users WHERE username = @username',
        parameters: {'username': username},
      );

      // Check if results list is empty
      final resultsList = results as List;
      if (resultsList.isEmpty) {
        return null;
      }

      final row = resultsList.first;
      return User(
        id: row[0] as int,
        username: row[1] as String,
        passwordHash: row[2] as String,
        salt: row[3] as String,
        role: row[4] as String,
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to get user by username: $username, using in-memory fallback', e, stackTrace);
      return _fallbackRepository.getUserByUsername(username);
    }
  }

  @override
  Future<User?> getUserById(int id, {Connection? conn}) async {
    try {
      final connection = conn ?? await getConnectionFn();
      final results = await connection.execute(
        'SELECT id, username, password_hash, salt, role FROM users WHERE id = @id',
        parameters: {'id': id},
      );

      // Check if results list is empty
      final resultsList = results as List;
      if (resultsList.isEmpty) {
        return null;
      }

      final row = resultsList.first;
      return User(
        id: row[0] as int,
        username: row[1] as String,
        passwordHash: row[2] as String,
        salt: row[3] as String,
        role: row[4] as String,
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to get user by ID: $id, using in-memory fallback', e, stackTrace);
      return _fallbackRepository.getUserById(id);
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

      final conn = await getConnectionFn();
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

      final resultsList = results as List;
      final row = resultsList.first;
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
      _log.warning('Failed to create user, using in-memory fallback', e, stackTrace);
      return _fallbackRepository.createUser(username, passwordHash, salt, role);
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
      _log.warning('Failed to verify credentials, using in-memory fallback', e, stackTrace);
      return _fallbackRepository.verifyCredentials(username, password);
    }
  }

  @override
  Future<bool> updatePassword(
    int userId,
    String newPasswordHash,
    String newSalt,
  ) async {
    try {
      final conn = await getConnectionFn();
      await conn.execute(
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

      // If no exception was thrown, consider it successful
      return true;
    } catch (e, stackTrace) {
      _log.warning('Failed to update password for user ID: $userId, using in-memory fallback', e, stackTrace);
      return _fallbackRepository.updatePassword(userId, newPasswordHash, newSalt);
    }
  }

  @override
  Future<bool> deleteUser(int userId) async {
    try {
      final conn = await getConnectionFn();
      await conn.execute(
        'DELETE FROM users WHERE id = @id',
        parameters: {'id': userId},
      );

      // If no exception was thrown, consider it successful
      return true;
    } catch (e, stackTrace) {
      _log.warning('Failed to delete user with ID: $userId, using in-memory fallback', e, stackTrace);
      return _fallbackRepository.deleteUser(userId);
    }
  }

  /// Hashes a password with the given salt using SHA-256.
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
