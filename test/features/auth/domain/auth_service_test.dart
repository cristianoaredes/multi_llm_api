import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:multi_llm_api/features/auth/data/models/refresh_token.dart';
import 'package:multi_llm_api/features/auth/data/models/user.dart';
import 'package:multi_llm_api/features/auth/domain/auth_service.dart';
import 'package:multi_llm_api/features/auth/domain/interfaces/i_refresh_token_repository.dart';
import 'package:multi_llm_api/features/auth/domain/interfaces/i_user_repository.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class MockUserRepository implements IUserRepository {
  final Map<String, User> _users = {
    'testuser': User(
      id: 1,
      username: 'testuser',
      passwordHash:
          '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', // 'password' hashed with SHA-256
      salt: '',
      role: 'user',
    ),
    'admin': User(
      id: 2,
      username: 'admin',
      passwordHash:
          '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', // 'password' hashed with SHA-256
      salt: '',
      role: 'admin',
    ),
  };

  @override
  Future<User?> getUserByUsername(String username) async {
    return _users[username];
  }

  @override
  Future<User?> getUserById(int id, {Connection? conn}) async {
    return _users.values.firstWhere(
      (user) => user.id == id,
      orElse: () => throw NotFoundException('User not found'),
    );
  }

  @override
  Future<User> createUser(
    String username,
    String passwordHash,
    String salt,
    String role,
  ) async {
    if (_users.containsKey(username)) {
      throw BadRequestException('Username already exists');
    }

    final user = User(
      id: _users.length + 1,
      username: username,
      passwordHash: passwordHash,
      salt: salt,
      role: role,
    );

    _users[username] = user;
    return user;
  }

  @override
  Future<User?> verifyCredentials(String username, String password) async {
    final user = await getUserByUsername(username);
    if (user == null) {
      return null;
    }

    // For testing purposes, we'll just check if the password is 'password'
    if (password == 'password') {
      return user;
    }

    return null;
  }

  @override
  Future<bool> updatePassword(
    int userId,
    String newPasswordHash,
    String newSalt,
  ) async {
    final user = _users.values.firstWhere(
      (u) => u.id == userId,
      orElse: () => throw NotFoundException('User not found'),
    );

    final updatedUser = User(
      id: user.id,
      username: user.username,
      passwordHash: newPasswordHash,
      salt: newSalt,
      role: user.role,
    );

    _users[user.username] = updatedUser;
    return true;
  }

  @override
  Future<bool> deleteUser(int userId) async {
    final userEntry = _users.entries.firstWhere(
      (entry) => entry.value.id == userId,
      orElse: () => throw NotFoundException('User not found'),
    );

    _users.remove(userEntry.key);
    return true;
  }
}

class MockRefreshTokenRepository implements IRefreshTokenRepository {
  final Map<String, RefreshToken> _tokens = {};
  int _nextId = 1;

  @override
  Future<RefreshToken> createToken(int userId, {Connection? conn}) async {
    final token = RefreshToken.generate(userId);
    final tokenWithId = RefreshToken(
      id: _nextId++,
      userId: token.userId,
      token: token.token,
      expiresAt: token.expiresAt,
      isRevoked: token.isRevoked,
    );

    _tokens[tokenWithId.token] = tokenWithId;
    return tokenWithId;
  }

  @override
  Future<RefreshToken?> findByToken(String token, {Connection? conn}) async {
    return _tokens[token];
  }

  @override
  Future<List<RefreshToken>> findByUserId(int userId,
      {Connection? conn}) async {
    return _tokens.values.where((token) => token.userId == userId).toList();
  }

  @override
  Future<bool> revokeToken(String token, {Connection? conn}) async {
    final refreshToken = _tokens[token];
    if (refreshToken == null) {
      return false;
    }

    _tokens[token] = refreshToken.copyWith(isRevoked: true);
    return true;
  }

  @override
  Future<int> revokeAllUserTokens(int userId, {Connection? conn}) async {
    final userTokens =
        _tokens.values.where((token) => token.userId == userId).toList();

    for (final token in userTokens) {
      _tokens[token.token] = token.copyWith(isRevoked: true);
    }

    return userTokens.length;
  }

  @override
  Future<int> deleteExpiredTokens({Connection? conn}) async {
    final now = DateTime.now();
    final expiredTokens =
        _tokens.values.where((token) => token.expiresAt.isBefore(now)).toList();

    for (final token in expiredTokens) {
      _tokens.remove(token.token);
    }

    return expiredTokens.length;
  }
}

void main() {
  late AuthService authService;
  late MockUserRepository mockUserRepository;
  late MockRefreshTokenRepository mockRefreshTokenRepository;

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockRefreshTokenRepository = MockRefreshTokenRepository();
    authService = AuthService(mockUserRepository, mockRefreshTokenRepository);
  });

  group('login', () {
    test('returns token for valid credentials', () async {
      final token = await authService.login('testuser', 'password');
      expect(token, isNotNull);
    });

    test('throws UnauthorizedException for invalid credentials', () async {
      expect(
        () => authService.login('testuser', 'wrongpassword'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws UnauthorizedException for non-existent user', () async {
      expect(
        () => authService.login('nonexistent', 'password'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('register', () {
    test('creates a new user with correct data', () async {
      final user = await authService.register('newuser', 'password123');
      expect(user.username, equals('newuser'));
      expect(user.role, equals('user'));
    });

    test('creates a new user with specified role', () async {
      final user =
          await authService.register('newadmin', 'password123', role: 'admin');
      expect(user.username, equals('newadmin'));
      expect(user.role, equals('admin'));
    });

    test('throws BadRequestException for existing username', () async {
      expect(
        () => authService.register('testuser', 'password123'),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('verifyToken', () {
    test('returns user for valid token', () async {
      final user = User(
        id: 1,
        username: 'testuser',
        passwordHash: 'hash',
        salt: 'salt',
        role: 'user',
      );
      final token = authService.generateToken(user);
      final verifiedUser = await authService.verifyToken(token);
      expect(verifiedUser.username, equals('testuser'));
    });

    test('throws UnauthorizedException for invalid token', () async {
      expect(
        () => authService.verifyToken('invalid.token.here'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('refreshToken', () {
    test('returns new access token for valid refresh token', () async {
      // Create a user and a refresh token
      final user = await mockUserRepository.getUserByUsername('testuser');
      final refreshToken =
          await mockRefreshTokenRepository.createToken(user!.id);

      // Refresh the token
      final newAccessToken = await authService.refreshToken(refreshToken.token);
      expect(newAccessToken, isNotNull);
    });

    test('throws UnauthorizedException for invalid refresh token', () async {
      expect(
        () => authService.refreshToken('invalid-refresh-token'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws UnauthorizedException for revoked refresh token', () async {
      // Create a user and a refresh token
      final user = await mockUserRepository.getUserByUsername('testuser');
      final refreshToken =
          await mockRefreshTokenRepository.createToken(user!.id);

      // Revoke the token
      await mockRefreshTokenRepository.revokeToken(refreshToken.token);

      // Try to refresh the token
      expect(
        () => authService.refreshToken(refreshToken.token),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('revokeToken', () {
    test('revokes a valid refresh token', () async {
      // Create a user and a refresh token
      final user = await mockUserRepository.getUserByUsername('testuser');
      final refreshToken =
          await mockRefreshTokenRepository.createToken(user!.id);

      // Revoke the token
      final result = await authService.revokeToken(refreshToken.token);
      expect(result, isTrue);

      // Verify the token is revoked
      final token =
          await mockRefreshTokenRepository.findByToken(refreshToken.token);
      expect(token!.isRevoked, isTrue);
    });

    test('returns false for non-existent token', () async {
      final result = await authService.revokeToken('non-existent-token');
      expect(result, isFalse);
    });
  });

  group('logout', () {
    test('logs out a user with a valid refresh token', () async {
      // Create a user and a refresh token
      final user = await mockUserRepository.getUserByUsername('testuser');
      final refreshToken =
          await mockRefreshTokenRepository.createToken(user!.id);

      // Logout
      final result = await authService.logout(refreshToken.token);
      expect(result, isTrue);

      // Verify the token is revoked
      final token =
          await mockRefreshTokenRepository.findByToken(refreshToken.token);
      expect(token!.isRevoked, isTrue);
    });

    test('returns false for non-existent token', () async {
      final result = await authService.logout('non-existent-token');
      expect(result, isFalse);
    });
  });

  group('revokeAllUserTokens', () {
    test('revokes all tokens for a user', () async {
      // Create a user and multiple refresh tokens
      final user = await mockUserRepository.getUserByUsername('testuser');
      await mockRefreshTokenRepository.createToken(user!.id);
      await mockRefreshTokenRepository.createToken(user.id);
      await mockRefreshTokenRepository.createToken(user.id);

      // Revoke all tokens
      final count = await authService.revokeAllUserTokens(user.id);
      expect(count, equals(3));

      // Verify all tokens are revoked
      final tokens = await mockRefreshTokenRepository.findByUserId(user.id);
      for (final token in tokens) {
        expect(token.isRevoked, isTrue);
      }
    });

    test('returns 0 for user with no tokens', () async {
      final count = await authService.revokeAllUserTokens(999);
      expect(count, equals(0));
    });
  });
}
