import 'dart:convert';
import 'dart:io';

import 'package:multi_llm_api/core/config/env_config.dart';
import 'package:multi_llm_api/core/di/injector.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  late Uri baseUri;
  late HttpServer server;

  setUpAll(() async {
    // Load environment variables
    await EnvConfig.loadEnv();

    // Setup dependency injection
    await setupInjector();

    // Start the server
    server = await startTestServer();
    baseUri = Uri.parse('http://localhost:${server.port}/api/v1');
  });

  tearDownAll(() async {
    // Stop the server
    await server.close(force: true);
  });

  group('Auth API', () {
    test('POST /auth/register creates a new user', () async {
      final registerData = {
        'username': 'testuser${DateTime.now().millisecondsSinceEpoch}',
        'password': 'password123',
      };

      final response = await http.post(
        baseUri.resolve('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerData),
      );

      expect(response.statusCode, equals(201));

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, contains('id'));
      expect(responseBody, contains('username'));
      expect(responseBody, contains('role'));
      expect(responseBody['username'], equals(registerData['username']));
      expect(responseBody['role'], equals('user'));
    });

    test('POST /auth/register with existing username returns 400', () async {
      // First, create a user
      final username = 'existinguser${DateTime.now().millisecondsSinceEpoch}';
      final registerData = {
        'username': username,
        'password': 'password123',
      };

      await http.post(
        baseUri.resolve('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerData),
      );

      // Try to create the same user again
      final response = await http.post(
        baseUri.resolve('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerData),
      );

      expect(response.statusCode, equals(400));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, contains('error'));
      expect(responseBody['error'], contains('Username already exists'));
    });

    test('POST /auth/login returns token for valid credentials', () async {
      // First, create a user
      final username = 'loginuser${DateTime.now().millisecondsSinceEpoch}';
      final password = 'password123';
      final registerData = {
        'username': username,
        'password': password,
      };

      await http.post(
        baseUri.resolve('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerData),
      );

      // Login with the created user
      final loginData = {
        'username': username,
        'password': password,
      };

      final response = await http.post(
        baseUri.resolve('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      expect(response.statusCode, equals(200));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, contains('token'));
      expect(responseBody['token'], isNotEmpty);
    });

    test('POST /auth/login returns 401 for invalid credentials', () async {
      final loginData = {
        'username': 'nonexistentuser',
        'password': 'wrongpassword',
      };

      final response = await http.post(
        baseUri.resolve('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      expect(response.statusCode, equals(401));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, contains('error'));
    });

    test('GET /auth/verify returns user data for valid token', () async {
      // First, create a user
      final username = 'verifyuser${DateTime.now().millisecondsSinceEpoch}';
      final password = 'password123';
      final registerData = {
        'username': username,
        'password': password,
      };

      await http.post(
        baseUri.resolve('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerData),
      );

      // Login to get a token
      final loginData = {
        'username': username,
        'password': password,
      };

      final loginResponse = await http.post(
        baseUri.resolve('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      final loginResponseBody =
          jsonDecode(loginResponse.body) as Map<String, dynamic>;
      final token = loginResponseBody['token'] as String;

      // Verify the token
      final response = await http.get(
        baseUri.resolve('/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      expect(response.statusCode, equals(200));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, contains('id'));
      expect(responseBody, contains('username'));
      expect(responseBody, contains('role'));
      expect(responseBody['username'], equals(username));
    });

    test('GET /auth/verify returns 401 for invalid token', () async {
      final response = await http.get(
        baseUri.resolve('/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer invalidtoken',
        },
      );

      expect(response.statusCode, equals(401));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, contains('error'));
    });
  });
}
