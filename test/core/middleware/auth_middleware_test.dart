import 'dart:convert';

import 'package:api_dart/core/di/injector.dart';
import 'package:api_dart/core/error/app_exception.dart';
import 'package:api_dart/core/middleware/auth_middleware.dart' as auth;
import 'package:api_dart/features/auth/data/models/user.dart';
import 'package:api_dart/features/auth/domain/auth_service_interface.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class MockAuthService implements IAuthService {
  final Map<String, User> _validTokens = {
    'valid_token': User(
      id: 1,
      username: 'testuser',
      passwordHash: 'hash',
      salt: 'salt',
      role: 'user',
    ),
    'admin_token': User(
      id: 2,
      username: 'admin',
      passwordHash: 'hash',
      salt: 'salt',
      role: 'admin',
    ),
  };

  @override
  Future<String> login(String username, String password) async {
    if (username == 'testuser' && password == 'password') {
      return 'valid_token';
    }
    if (username == 'admin' && password == 'admin_password') {
      return 'admin_token';
    }
    throw UnauthorizedException('Invalid username or password');
  }

  @override
  Future<User> register(String username, String password, {String? role}) async {
    return User(
      id: 3,
      username: username,
      passwordHash: 'hash',
      salt: 'salt',
      role: role ?? 'user',
    );
  }

  @override
  Future<User> verifyToken(String token) async {
    final user = _validTokens[token];
    if (user == null) {
      throw UnauthorizedException('Invalid token');
    }
    return user;
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    if (refreshToken == 'valid_refresh_token') {
      return 'valid_token';
    }
    throw UnauthorizedException('Invalid refresh token');
  }

  @override
  Future<bool> revokeToken(String refreshToken) async {
    return refreshToken == 'valid_refresh_token';
  }

  @override
  Future<int> revokeAllUserTokens(int userId) async {
    return userId == 1 ? 2 : 0;
  }

  @override
  Future<bool> logout(String refreshToken) async {
    return refreshToken == 'valid_refresh_token';
  }
}

void main() {
  late Middleware middleware;
  late Handler innerHandler;
  late MockAuthService mockAuthService;

  setUp(() {
    // Setup a mock auth service
    mockAuthService = MockAuthService();
    
    // Register the mock auth service with the injector
    injector.registerSingleton<IAuthService>(mockAuthService);
    
    // Create the auth middleware
    middleware = auth.authMiddleware();
    
    // Setup a simple inner handler that returns the user from the request context
    innerHandler = (request) async {
      final user = request.context['user'] as User?;
      final userId = request.context['userId'] as int?;
      final userRole = request.context['userRole'] as String?;
      
      return Response.ok(
        jsonEncode({
          'user': user?.username,
          'userId': userId,
          'userRole': userRole,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    };
  });

  tearDown(() {
    // Reset the injector
    injector.reset();
  });

  group('AuthMiddleware', () {
    test('allows access to unprotected paths', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/health'),
      );

      final handler = middleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
    });

    test('allows access to docs paths', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/docs'),
      );

      final handler = middleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
    });

    test('allows access to openapi paths', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/openapi'),
      );

      final handler = middleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
    });

    test('allows access to favicon.ico', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/favicon.ico'),
      );

      final handler = middleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
    });

    test('allows access to unprotected API paths', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/auth/login'),
      );

      final handler = middleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
    });

    test('blocks access to protected API paths without token', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/v1/items'),
      );

      final handler = middleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<UnauthorizedException>().having(
          (e) => e.message,
          'message',
          'Missing or invalid authorization header',
        )),
      );
    });

    test('blocks access to protected API paths with invalid token format', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/v1/items'),
        headers: {'authorization': 'InvalidFormat token'},
      );

      final handler = middleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<UnauthorizedException>().having(
          (e) => e.message,
          'message',
          'Missing or invalid authorization header',
        )),
      );
    });

    test('blocks access to protected API paths with invalid token', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/v1/items'),
        headers: {'authorization': 'Bearer invalid_token'},
      );

      final handler = middleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('allows access to protected API paths with valid token', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/v1/items'),
        headers: {'authorization': 'Bearer valid_token'},
      );

      final handler = middleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['user'], equals('testuser'));
      expect(body['userId'], equals(1));
      expect(body['userRole'], equals('user'));
    });

    test('adds user context to request with valid token', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/v1/items'),
        headers: {'authorization': 'Bearer admin_token'},
      );

      final handler = middleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['user'], equals('admin'));
      expect(body['userId'], equals(2));
      expect(body['userRole'], equals('admin'));
    });

    test('blocks access to non-API paths that are not explicitly unprotected', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/some/random/path'),
      );

      final handler = middleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<UnauthorizedException>().having(
          (e) => e.message,
          'message',
          'Access denied.',
        )),
      );
    });
  });
}
