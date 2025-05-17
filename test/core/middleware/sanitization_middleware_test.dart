import 'dart:convert';

import 'package:multi_llm_api/core/middleware/sanitization_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('SanitizationMiddleware', () {
    late Handler innerHandler;
    late Middleware middleware;
    late Handler handler;

    setUp(() {
      // Configure o handler interno para ecoar o corpo da requisição
      innerHandler = (Request request) async {
        final body = await request.readAsString();
        return Response.ok(body);
      };

      // Crie o middleware de sanitização
      middleware = SanitizationMiddleware.create();

      // Combine o middleware com o handler
      handler = middleware(innerHandler);
    });

    test('should sanitize string values in JSON body for POST requests',
        () async {
      // Crie uma requisição POST com um corpo JSON contendo strings potencialmente perigosas
      final requestBody = jsonEncode({
        'name': "John O'Connor",
        'description': '<script>alert("XSS")</script>',
        'query': "DROP TABLE users; --",
      });

      final request = Request(
        'POST',
        Uri.parse('https://example.com/api/test'),
        body: requestBody,
      );

      // Execute a requisição através do middleware
      final response = await handler(request);

      // Leia o corpo da resposta (que deve ser o corpo sanitizado)
      final responseBody = await response.readAsString();
      final decodedBody = jsonDecode(responseBody) as Map<String, dynamic>;

      // Verifique se as strings foram sanitizadas
      expect(decodedBody['name'], equals("John O''Connor"));
      expect(decodedBody['description'], isNot(contains('<script>')));
      expect(decodedBody['query'], isNot(contains('DROP TABLE')));
    });

    test('should sanitize nested JSON objects recursively', () async {
      // Crie uma requisição com objetos JSON aninhados
      final requestBody = jsonEncode({
        'user': {
          'name': "Robert'); DROP TABLE users; --",
          'profile': {
            'bio': '<img src="x" onerror="alert(1)">',
          },
        },
        'tags': ['normal', '<script>bad</script>', "O'Reilly"],
      });

      final request = Request(
        'POST',
        Uri.parse('https://example.com/api/test'),
        body: requestBody,
      );

      // Execute a requisição através do middleware
      final response = await handler(request);

      // Leia o corpo da resposta
      final responseBody = await response.readAsString();
      final decodedBody = jsonDecode(responseBody) as Map<String, dynamic>;

      // Verifique se objetos aninhados foram sanitizados
      final user = decodedBody['user'] as Map<String, dynamic>;
      final profile = user['profile'] as Map<String, dynamic>;
      final tags = decodedBody['tags'] as List<dynamic>;

      expect(user['name'], isNot(contains('DROP TABLE')));
      expect(profile['bio'], isNot(contains('onerror')));
      expect(tags[1], isNot(contains('<script>')));
      expect(tags[2], equals("O''Reilly"));
    });

    test('should pass through GET requests without modification', () async {
      // Crie uma requisição GET
      final request = Request(
        'GET',
        Uri.parse('https://example.com/api/test?query=value'),
      );

      // Crie um handler especial para GET que apenas retorna uma mensagem
      final getHandler = middleware((Request req) async {
        return Response.ok(jsonEncode({'message': 'GET request received'}));
      });

      final response = await getHandler(request);
      final responseBody = await response.readAsString();
      final decodedBody = jsonDecode(responseBody) as Map<String, dynamic>;

      expect(decodedBody['message'], equals('GET request received'));
    });

    test('should handle empty request bodies gracefully', () async {
      // Crie uma requisição POST sem corpo
      final request = Request(
        'POST',
        Uri.parse('https://example.com/api/test'),
      );

      final response = await handler(request);
      final responseBody = await response.readAsString();

      expect(responseBody, isEmpty);
    });

    test('should handle non-JSON request bodies gracefully', () async {
      // Crie uma requisição POST com corpo não-JSON
      final request = Request(
        'POST',
        Uri.parse('https://example.com/api/test'),
        body: 'This is not a JSON string',
      );

      final response = await handler(request);
      final responseBody = await response.readAsString();

      expect(responseBody, equals('This is not a JSON string'));
    });
  });
}
