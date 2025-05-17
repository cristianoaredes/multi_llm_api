import 'package:api_dart/features/auth/data/models/user.dart';
import 'package:postgres/postgres.dart';

/// Abstract interface defining data operations for [User] entities.
/// This acts as the contract for user data persistence.
abstract class IUserRepository {
  /// Retrieves a user by their username.
  /// Returns `null` if the user is not found.
  Future<User?> getUserByUsername(String username);

  /// Retrieves a user by their ID.
  /// Returns `null` if the user is not found.
  Future<User?> getUserById(int id, {Connection? conn});

  /// Creates a new user with the given details.
  /// Returns the created user with its assigned ID.
  Future<User> createUser(
    String username,
    String passwordHash,
    String salt,
    String role,
  );

  /// Verifies if the provided credentials are valid.
  /// Returns the user if valid, `null` otherwise.
  Future<User?> verifyCredentials(String username, String password);
  
  /// Updates a user's password.
  /// Returns `true` if the update was successful, `false` otherwise.
  Future<bool> updatePassword(
    int userId,
    String newPasswordHash,
    String newSalt,
  );
  
  /// Deletes a user by their ID.
  /// Returns `true` if the user was successfully deleted, `false` otherwise.
  Future<bool> deleteUser(int userId);
}
