import 'dart:convert';

import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:multi_llm_api/core/middleware/validation_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late Handler innerHandler;
  late Middleware validationMiddleware;
  late Map<String, Map<String, ValidationFunction>> validations;

  setUp(() {
    // Setup a simple inner handler that returns a 200 response
    innerHandler = (request) async {
      return Response.ok('Success');
    };

    // Setup validations for testing
    validations = {
      '/api/v1/test': {
        'POST': (Map<String, dynamic> body) {
          if (!body.containsKey('name')) {
            throw FormatException('Name is required');
          }
          if (body['name'] is! String) {
            throw FormatException('Name must be a string');
          }
          if ((body['name'] as String).isEmpty) {
            throw FormatException('Name cannot be empty');
          }
          return body;
        },
      },
    };

    // Create the validation middleware
    validationMiddleware = ValidationMiddleware.create(validations);
  });

  group('ValidationMiddleware', () {
    test('passes through requests for paths not requiring validation', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/v1/other'),
      );

      final handler = validationMiddleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
    });

    test('passes through requests for methods not requiring validation', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/v1/test'),
      );

      final handler = validationMiddleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
    });

    test('validates valid request body successfully', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/test'),
        body: jsonEncode({'name': 'Test Name'}),
      );

      final handler = validationMiddleware(innerHandler);
      final response = await handler(request);

      expect(response.statusCode, equals(200));
    });

    test('throws BadRequestException for empty request body', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/test'),
        body: '',
      );

      final handler = validationMiddleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          'Request body cannot be empty',
        )),
      );
    });

    test('throws BadRequestException for invalid JSON', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/test'),
        body: '{invalid json',
      );

      final handler = validationMiddleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          'Invalid JSON in request body',
        )),
      );
    });

    test('throws BadRequestException for non-object JSON', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/test'),
        body: jsonEncode(['array', 'not', 'object']),
      );

      final handler = validationMiddleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          'Request body must be a JSON object',
        )),
      );
    });

    test('throws BadRequestException for validation errors', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/test'),
        body: jsonEncode({'other': 'field'}),
      );

      final handler = validationMiddleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          'Validation error: Name is required',
        )),
      );
    });

    test('throws BadRequestException for empty name', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/test'),
        body: jsonEncode({'name': ''}),
      );

      final handler = validationMiddleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          'Validation error: Name cannot be empty',
        )),
      );
    });

    test('throws BadRequestException for wrong type', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/test'),
        body: jsonEncode({'name': 123}),
      );

      final handler = validationMiddleware(innerHandler);

      expect(
        () => handler(request),
        throwsA(isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          'Validation error: Name must be a string',
        )),
      );
    });
  });
}
