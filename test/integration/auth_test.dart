import 'dart:convert';
import 'dart:io';

import 'package:api_dart/core/config/env_config.dart';
import 'package:api_dart/core/di/injector.dart';
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

  group('/api/v1/auth/login Endpoint', () {
    test('should return 200 and token for valid credentials', () async {
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

    test('should return 401 for invalid credentials', () async {
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

    test('should return 400 for missing username', () async {
      final response = await http.post(
        baseUri.resolve('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': 'password'}), // Missing username
      );

      expect(response.statusCode, equals(400));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, contains('error'));
    });

    test('should return 400 for missing password', () async {
      final response = await http.post(
        baseUri.resolve('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': 'user'}), // Missing password
      );

      expect(response.statusCode, equals(400));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, contains('error'));
    });

    test('should return 400 for empty body', () async {
      final response = await http.post(
        baseUri.resolve('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}), // Empty body
      );

      expect(response.statusCode, equals(400));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, contains('error'));
    });
  });
}
