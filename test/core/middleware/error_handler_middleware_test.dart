import 'dart:convert';

import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:multi_llm_api/core/error/error_handler_middleware.dart';
import 'package:multi_llm_api/core/presentation/dtos/error_response_dto.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late Middleware middleware;
  late Handler innerHandler;
  late Handler errorThrowingHandler;
  late Handler notFoundHandler;
  late Handler badRequestHandler;
  late Handler unauthorizedHandler;
  late Handler forbiddenHandler;
  late Handler internalServerHandler;

  setUp(() {
    // Create the error handler middleware
    middleware = errorHandlerMiddleware();
    
    // Setup a simple inner handler that returns a 200 response
    innerHandler = (request) async {
      return Response.ok('Success');
    };
    
    // Setup handlers that throw different types of exceptions
    errorThrowingHandler = (request) async {
      throw Exception('Generic error');
    };
    
    notFoundHandler = (request) async {
      throw NotFoundException('Resource not found');
    };
    
    badRequestHandler = (request) async {
      throw BadRequestException('Invalid request');
    };
    
    unauthorizedHandler = (request) async {
      throw UnauthorizedException('Unauthorized access');
    };
    
    forbiddenHandler = (request) async {
      throw ForbiddenException('Forbidden access');
    };
    
    internalServerHandler = (request) async {
      throw InternalServerException('Internal server error');
    };
  });

  group('ErrorHandlerMiddleware', () {
    test('passes through successful responses', () async {
      final request = Request('GET', Uri.parse('http://localhost/'));
      final handler = middleware(innerHandler);
      final response = await handler(request);
      
      expect(response.statusCode, equals(200));
      expect(await response.readAsString(), equals('Success'));
    });
    
    test('handles NotFoundException with 404 status code', () async {
      final request = Request('GET', Uri.parse('http://localhost/'));
      final handler = middleware(notFoundHandler);
      final response = await handler(request);
      
      expect(response.statusCode, equals(404));
      
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final errorResponse = ErrorResponseDto.fromJson(body);
      
      expect(errorResponse.code, equals('NOT_FOUND'));
      expect(errorResponse.message, equals('Resource not found'));
    });
    
    test('handles BadRequestException with 400 status code', () async {
      final request = Request('GET', Uri.parse('http://localhost/api/test'));
      final handler = middleware(badRequestHandler);
      final response = await handler(request);
      
      expect(response.statusCode, equals(400));
      
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final errorResponse = ErrorResponseDto.fromJson(body);
      
      expect(errorResponse.code, equals('BAD_REQUEST'));
      expect(errorResponse.message, equals('Invalid request'));
    });
    
    test('handles UnauthorizedException with 401 status code', () async {
      final request = Request('GET', Uri.parse('http://localhost/api/secure'));
      final handler = middleware(unauthorizedHandler);
      final response = await handler(request);
      
      expect(response.statusCode, equals(401));
      
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final errorResponse = ErrorResponseDto.fromJson(body);
      
      expect(errorResponse.code, equals('UNAUTHORIZED'));
      expect(errorResponse.message, equals('Unauthorized access'));
    });
    
    test('handles ForbiddenException with 403 status code', () async {
      final request = Request('GET', Uri.parse('http://localhost/api/admin'));
      final handler = middleware(forbiddenHandler);
      final response = await handler(request);
      
      expect(response.statusCode, equals(403));
      
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final errorResponse = ErrorResponseDto.fromJson(body);
      
      expect(errorResponse.code, equals('FORBIDDEN'));
      expect(errorResponse.message, equals('Forbidden access'));
    });
    
    test('handles InternalServerException with 500 status code', () async {
      final request = Request('GET', Uri.parse('http://localhost/api/error'));
      final handler = middleware(internalServerHandler);
      final response = await handler(request);
      
      expect(response.statusCode, equals(500));
      
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final errorResponse = ErrorResponseDto.fromJson(body);
      
      expect(errorResponse.code, equals('INTERNAL_SERVER_ERROR'));
      expect(errorResponse.message, equals('Internal server error'));
    });
    
    test('handles generic exceptions with 500 status code', () async {
      final request = Request('GET', Uri.parse('http://localhost/api/unknown'));
      final handler = middleware(errorThrowingHandler);
      final response = await handler(request);
      
      expect(response.statusCode, equals(500));
      
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final errorResponse = ErrorResponseDto.fromJson(body);
      
      expect(errorResponse.code, equals('INTERNAL_SERVER_ERROR'));
      expect(errorResponse.message, equals('An unexpected error occurred on the server.'));
    });
    
    test('includes correct Content-Type header', () async {
      final request = Request('GET', Uri.parse('http://localhost/'));
      final handler = middleware(notFoundHandler);
      final response = await handler(request);
      
      expect(response.headers['content-type'], equals('application/json'));
    });
  });
}
