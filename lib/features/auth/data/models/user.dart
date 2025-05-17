/// {@template user_model}
/// Represents a user entity within the application domain.
///
/// This class is used in the data and domain layers for authentication.
/// {@endtemplate}
class User {
  /// {@macro user_model}
  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.role,
  });

  /// Creates a User from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    // Basic validation
    if (json['id'] == null ||
        json['username'] == null ||
        json['password_hash'] == null ||
        json['salt'] == null ||
        json['role'] == null) {
      throw const FormatException('Invalid JSON structure for User');
    }

    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      passwordHash: json['password_hash'] as String,
      salt: json['salt'] as String,
      role: json['role'] as String,
    );
  }

  /// The unique identifier for the user.
  final int id;
  
  /// The username of the user.
  final String username;
  
  /// The hashed password of the user.
  final String passwordHash;
  
  /// The salt used for password hashing.
  final String salt;
  
  /// The role of the user (e.g., 'user', 'admin').
  final String role;

  /// Converts the User object to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'password_hash': passwordHash,
    'salt': salt,
    'role': role,
  };
}
