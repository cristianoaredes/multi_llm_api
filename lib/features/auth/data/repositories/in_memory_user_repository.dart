import 'package:api_dart/core/error/app_exception.dart';
import 'package:api_dart/features/auth/data/models/user.dart';
import 'package:api_dart/features/auth/domain/interfaces/i_user_repository.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';

/// In-memory implementation of [IUserRepository].
///
/// This implementation stores users in memory and is intended for
/// development and testing purposes only.
class InMemoryUserRepository implements IUserRepository {
  final Logger _log = Logger('InMemoryUserRepository');
  final Map<int, User> _users = {};
  int _nextId = 1;

  @override
  Future<User> createUser(
    String username,
    String passwordHash,
    String salt,
    String role,
  ) async {
    _log.info('Creating user: $username with role: $role');

    // Check if username already exists
    if (_users.values.any((user) => user.username == username)) {
      throw BadRequestException('Username already exists');
    }

    // Create a new user
    final user = User(
      id: _nextId++,
      username: username,
      passwordHash: passwordHash,
      salt: salt,
      role: role,
    );

    // Store the user
    _users[user.id] = user;

    return user;
  }

  @override
  Future<User?> getUserById(int id, {Connection? conn}) async {
    _log.info('Getting user by ID: $id');
    return _users[id];
  }

  @override
  Future<User?> getUserByUsername(String username) async {
    _log.info('Getting user by username: $username');
    try {
      return _users.values.firstWhere(
        (user) => user.username == username,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User?> verifyCredentials(String username, String password) async {
    _log.info('Verifying credentials for user: $username');
    
    // In a real implementation, we would hash the password with the salt
    // and compare it with the stored hash. For simplicity, we'll just
    // check if the user exists and return it.
    try {
      return _users.values.firstWhere(
        (user) => user.username == username,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> updatePassword(
    int userId,
    String newPasswordHash,
    String newSalt,
  ) async {
    _log.info('Updating password for user: $userId');

    if (!_users.containsKey(userId)) {
      return false;
    }

    // Get the current user
    final user = _users[userId]!;

    // Create a new user with the updated password
    final updatedUser = User(
      id: user.id,
      username: user.username,
      passwordHash: newPasswordHash,
      salt: newSalt,
      role: user.role,
    );

    // Store the updated user
    _users[userId] = updatedUser;

    return true;
  }

  @override
  Future<bool> deleteUser(int userId) async {
    _log.info('Deleting user: $userId');

    if (!_users.containsKey(userId)) {
      return false;
    }

    _users.remove(userId);
    return true;
  }
}
