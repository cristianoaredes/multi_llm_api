import 'package:uuid/uuid.dart';

/// Model representing a refresh token.
///
/// Refresh tokens are used to obtain new access tokens when the current
/// access token expires, without requiring the user to log in again.
class RefreshToken {
  /// Creates a new [RefreshToken].
  RefreshToken({
    required this.id,
    required this.userId,
    required this.token,
    required this.expiresAt,
    this.isRevoked = false,
  });

  /// Creates a new [RefreshToken] with a generated token and expiration date.
  ///
  /// [userId] is the ID of the user this token belongs to.
  /// [expiresInDays] is the number of days until the token expires.
  factory RefreshToken.generate(int userId, {int expiresInDays = 30}) {
    final uuid = const Uuid().v4();
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: expiresInDays));

    return RefreshToken(
      id: 0, // Will be set by the database
      userId: userId,
      token: uuid,
      expiresAt: expiresAt,
    );
  }

  /// The unique identifier for this refresh token.
  final int id;

  /// The ID of the user this token belongs to.
  final int userId;

  /// The token value.
  final String token;

  /// The date and time when this token expires.
  final DateTime expiresAt;

  /// Whether this token has been revoked.
  final bool isRevoked;

  /// Checks if this token is expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Checks if this token is valid (not expired and not revoked).
  bool get isValid => !isExpired && !isRevoked;

  /// Creates a copy of this token with the given fields replaced with new values.
  RefreshToken copyWith({
    int? id,
    int? userId,
    String? token,
    DateTime? expiresAt,
    bool? isRevoked,
  }) {
    return RefreshToken(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      isRevoked: isRevoked ?? this.isRevoked,
    );
  }

  /// Converts this token to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
      'isRevoked': isRevoked,
    };
  }

  /// Creates a [RefreshToken] from a JSON map.
  factory RefreshToken.fromJson(Map<String, dynamic> json) {
    return RefreshToken(
      id: json['id'] as int,
      userId: json['userId'] as int,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isRevoked: json['isRevoked'] as bool? ?? false,
    );
  }

  /// Creates a [RefreshToken] from a database row.
  factory RefreshToken.fromDatabaseRow(List<dynamic> row) {
    return RefreshToken(
      id: row[0] as int,
      userId: row[1] as int,
      token: row[2] as String,
      expiresAt: row[3] as DateTime,
      isRevoked: row[4] as bool? ?? false,
    );
  }
}
