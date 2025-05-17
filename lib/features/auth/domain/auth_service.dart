import 'dart:convert';
import 'dart:math';

import 'package:api_dart/core/config/env_config.dart';
import 'package:api_dart/core/error/app_exception.dart';
import 'package:api_dart/features/auth/data/models/user.dart';
import 'package:api_dart/features/auth/domain/auth_service_interface.dart';
import 'package:api_dart/features/auth/domain/interfaces/i_refresh_token_repository.dart';
import 'package:api_dart/features/auth/domain/interfaces/i_user_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logging/logging.dart';

/// {@template auth_service}
/// Handles authentication logic, including token validation and user login.
///
/// Uses JWT for token generation and validation.
/// {@endtemplate}
class AuthService implements IAuthService {
  /// {@macro auth_service}
  AuthService(this._userRepository, this._refreshTokenRepository);

  final IUserRepository _userRepository;
  final IRefreshTokenRepository _refreshTokenRepository;
  final Logger _log = Logger('AuthService');

  /// Authenticates a token by verifying its signature and expiration.
  ///
  /// Returns `true` if the token is valid, `false` otherwise.
  bool authenticate(String token) {
    try {
      // Verify the token is valid and not expired
      final isValid = !JwtDecoder.isExpired(token);
      
      // Verify the token signature
      final jwt = JWT.verify(token, SecretKey(EnvConfig.jwtSecret));
      
      // Check if the token has the required claims
      final payload = jwt.payload as Map<String, dynamic>;
      return isValid && payload.containsKey('sub') && payload.containsKey('role');
    } catch (e) {
      _log.warning('Token validation failed: $e');
      return false;
    }
  }

  @override
  Future<String> login(String username, String password) async {
    try {
      final user = await _userRepository.verifyCredentials(username, password);
      if (user == null) {
        throw UnauthorizedException('Invalid username or password');
      }
      
      // Generate access token
      final accessToken = generateToken(user);
      
      // Generate refresh token
      await _refreshTokenRepository.createToken(user.id);
      
      return accessToken;
    } catch (e, stackTrace) {
      if (e is AppException) {
        rethrow;
      }
      _log.severe('Login failed', e, stackTrace);
      throw InternalServerException('Failed to login');
    }
  }

  @override
  Future<User> register(String username, String password, {String? role}) async {
    try {
      // Generate a random salt
      final salt = _generateSalt();
      
      // Hash the password with the salt
      final passwordHash = _hashPassword(password, salt);
      
      // Create the user
      return await _userRepository.createUser(
        username, 
        passwordHash, 
        salt, 
        role ?? 'user',
      );
    } catch (e, stackTrace) {
      _log.severe('Registration failed', e, stackTrace);
      if (e is BadRequestException) {
        rethrow;
      }
      throw InternalServerException('Failed to register user');
    }
  }

  @override
  Future<User> verifyToken(String token) async {
    try {
      // Verify the token is valid and not expired
      if (JwtDecoder.isExpired(token)) {
        throw UnauthorizedException('Token expired');
      }
      
      // Verify the token signature
      final jwt = JWT.verify(token, SecretKey(EnvConfig.jwtSecret));
      
      // Extract the user ID from the token
      final payload = jwt.payload as Map<String, dynamic>;
      if (!payload.containsKey('sub')) {
        throw UnauthorizedException('Invalid token');
      }
      
      final userId = int.tryParse(payload['sub'].toString());
      if (userId == null) {
        throw UnauthorizedException('Invalid token');
      }
      
      // Extract the username from the token
      final username = payload['username'] as String?;
      if (username == null) {
        throw UnauthorizedException('Invalid token');
      }
      
      // Get the user from the repository
      final user = await _userRepository.getUserByUsername(username);
      if (user == null) {
        throw UnauthorizedException('User not found');
      }
      
      return user;
    } catch (e, stackTrace) {
      if (e is UnauthorizedException) {
        rethrow;
      }
      _log.severe('Token verification failed', e, stackTrace);
      throw UnauthorizedException('Invalid token');
    }
  }

  @override
  Future<String> refreshToken(String refreshTokenStr) async {
    try {
      // Find the refresh token in the database
      final refreshToken = await _refreshTokenRepository.findByToken(refreshTokenStr);
      
      // Check if the token exists and is valid
      if (refreshToken == null) {
        throw UnauthorizedException('Invalid refresh token');
      }
      
      if (!refreshToken.isValid) {
        throw UnauthorizedException('Refresh token expired or revoked');
      }
      
      // Get the user associated with the token
      final user = await _userRepository.getUserById(refreshToken.userId);
      if (user == null) {
        throw UnauthorizedException('User not found');
      }
      
      // Generate a new access token
      return generateToken(user);
    } catch (e, stackTrace) {
      if (e is UnauthorizedException) {
        rethrow;
      }
      _log.severe('Token refresh failed', e, stackTrace);
      throw UnauthorizedException('Failed to refresh token');
    }
  }

  @override
  Future<bool> revokeToken(String refreshTokenStr) async {
    try {
      return await _refreshTokenRepository.revokeToken(refreshTokenStr);
    } catch (e, stackTrace) {
      _log.severe('Token revocation failed', e, stackTrace);
      throw InternalServerException('Failed to revoke token');
    }
  }

  @override
  Future<int> revokeAllUserTokens(int userId) async {
    try {
      return await _refreshTokenRepository.revokeAllUserTokens(userId);
    } catch (e, stackTrace) {
      _log.severe('Failed to revoke all user tokens', e, stackTrace);
      throw InternalServerException('Failed to revoke all user tokens');
    }
  }

  @override
  Future<bool> logout(String refreshTokenStr) async {
    try {
      return await revokeToken(refreshTokenStr);
    } catch (e, stackTrace) {
      _log.severe('Logout failed', e, stackTrace);
      throw InternalServerException('Failed to logout');
    }
  }

  /// Validates a token and returns the user ID if valid.
  ///
  /// Returns the user ID if the token is valid, `null` otherwise.
  int? validateToken(String token) {
    try {
      // Verify the token is valid and not expired
      if (JwtDecoder.isExpired(token)) {
        return null;
      }
      
      // Verify the token signature
      final jwt = JWT.verify(token, SecretKey(EnvConfig.jwtSecret));
      
      // Extract the user ID from the token
      final payload = jwt.payload as Map<String, dynamic>;
      if (!payload.containsKey('sub')) {
        return null;
      }
      
      return int.tryParse(payload['sub'].toString());
    } catch (e) {
      _log.warning('Token validation failed: $e');
      return null;
    }
  }

  /// Gets a user from a token.
  ///
  /// Returns the user if the token is valid, `null` otherwise.
  Future<User?> getUserFromToken(String token) async {
    final userId = validateToken(token);
    if (userId == null) {
      return null;
    }
    
    try {
      // Extract the username from the token
      final decodedToken = JwtDecoder.decode(token);
      final username = decodedToken['username'] as String?;
      
      if (username == null) {
        return null;
      }
      
      // Get the user from the repository
      return await _userRepository.getUserByUsername(username);
    } catch (e, stackTrace) {
      _log.severe('Failed to get user from token', e, stackTrace);
      return null;
    }
  }

  /// Generates a JWT token for a user.
  ///
  /// Returns the generated token.
  String generateToken(User user) {
    // Create a JWT token
    final jwt = JWT(
      {
        'sub': user.id.toString(),
        'username': user.username,
        'role': user.role,
      },
      issuer: 'api_dart',
    );
    
    // Sign the token with the secret key
    return jwt.sign(
      SecretKey(EnvConfig.jwtSecret),
      expiresIn: Duration(hours: EnvConfig.jwtExpirationHours),
    );
  }

  /// Generates a random salt for password hashing.
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hashes a password with the given salt using SHA-256.
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
