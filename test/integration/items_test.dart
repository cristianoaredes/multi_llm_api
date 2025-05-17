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
  String? authToken; // To store the auth token
  int? createdItemId; // To store the ID of the created item

  setUpAll(() async {
    // Load environment variables
    await EnvConfig.loadEnv();

    // Setup dependency injection
    await setupInjector();

    // Start the server
    server = await startTestServer();
    baseUri = Uri.parse('http://localhost:${server.port}/api/v1');

    // Create a user for authentication
    final username = 'itemsuser${DateTime.now().millisecondsSinceEpoch}';
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

    if (loginResponse.statusCode == 200) {
      final loginResponseBody = jsonDecode(loginResponse.body) as Map<String, dynamic>;
      authToken = loginResponseBody['token'] as String?;
    } else {
      throw Exception('Failed to login for integration tests');
    }
    expect(authToken, isNotNull); // Ensure token was received
  });

  tearDownAll(() async {
    // Stop the server
    await server.close(force: true);
  });

  group('/items Endpoint (Integration)', () {
    test('POST /items should create a new item', () async {
      final response = await http.post(
        baseUri.resolve('/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'name': 'Test Item', 'description': 'Created via test'}),
      );

      expect(response.statusCode, equals(201)); // Expect Created status
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, containsPair('name', 'Test Item'));
      expect(responseBody, containsPair('description', 'Created via test'));
      expect(responseBody, contains('id'));
      
      createdItemId = responseBody['id'] as int?;
      expect(createdItemId, isNotNull);
    });

    test('GET /items should list items including the created one', () async {
      expect(createdItemId, isNotNull, reason: 'Created item ID is needed');
      
      final response = await http.get(
        baseUri.resolve('/items'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(response.statusCode, equals(200));
      final responseBody = jsonDecode(response.body) as List<dynamic>;
      expect(responseBody, isNotEmpty);
      
      // Check if the created item is in the list
      expect(
        responseBody.any((item) => item['id'] == createdItemId && item['name'] == 'Test Item'),
        isTrue,
      );
    });

    test('GET /items/{id} should retrieve the created item', () async {
      expect(createdItemId, isNotNull, reason: 'Created item ID is needed');
      
      final response = await http.get(
        baseUri.resolve('/items/$createdItemId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(response.statusCode, equals(200));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, containsPair('id', createdItemId));
      expect(responseBody, containsPair('name', 'Test Item'));
    });

    test('PUT /items/{id} should update the created item', () async {
      expect(createdItemId, isNotNull, reason: 'Created item ID is needed');
      
      final response = await http.put(
        baseUri.resolve('/items/$createdItemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'name': 'Updated Test Item', 'description': 'Updated via test'}),
      );

      expect(response.statusCode, equals(200));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, containsPair('id', createdItemId));
      expect(responseBody, containsPair('name', 'Updated Test Item'));
      expect(responseBody, containsPair('description', 'Updated via test'));
    });

    test('GET /items/{id} should retrieve the updated item', () async {
      expect(createdItemId, isNotNull, reason: 'Created item ID is needed');
      
      final response = await http.get(
        baseUri.resolve('/items/$createdItemId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(response.statusCode, equals(200));
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseBody, containsPair('id', createdItemId));
      expect(responseBody, containsPair('name', 'Updated Test Item')); // Check updated name
    });

    test('DELETE /items/{id} should delete the created item', () async {
      expect(createdItemId, isNotNull, reason: 'Created item ID is needed');
      
      final response = await http.delete(
        baseUri.resolve('/items/$createdItemId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(response.statusCode, equals(204)); // Expect No Content status
    });

    test('GET /items/{id} should return 404 after deletion', () async {
      expect(createdItemId, isNotNull, reason: 'Created item ID is needed');
      
      final response = await http.get(
        baseUri.resolve('/items/$createdItemId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(response.statusCode, equals(404)); // Expect Not Found
    });

    test('GET /items should not list the deleted item', () async {
      expect(createdItemId, isNotNull, reason: 'Created item ID is needed');
      
      final response = await http.get(
        baseUri.resolve('/items'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(response.statusCode, equals(200));
      final responseBody = jsonDecode(response.body) as List<dynamic>;
      
      // Check if the deleted item is NOT in the list
      expect(
        responseBody.any((item) => item['id'] == createdItemId),
        isFalse,
      );
    });
  });
}
