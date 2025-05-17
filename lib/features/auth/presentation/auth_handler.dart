import 'dart:convert';

import 'package:api_dart/core/di/injector.dart';
import 'package:api_dart/core/error/app_exception.dart';
import 'package:api_dart/features/auth/domain/auth_service_interface.dart';
import 'package:api_dart/features/auth/presentation/dtos/login_request_dto.dart';
import 'package:api_dart/features/auth/presentation/dtos/login_response_dto.dart';
import 'package:api_dart/features/auth/presentation/dtos/refresh_token_request_dto.dart';
import 'package:api_dart/features/auth/presentation/dtos/register_request_dto.dart';
import 'package:api_dart/features/auth/presentation/dtos/user_response_dto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Handles HTTP requests for authentication endpoints.
class AuthHandler {
  // Inject the interface instead of the concrete class
  final IAuthService _authService = injector<IAuthService>();

  /// Provides the configured router for authentication routes.
  Router get router {
    final router = Router()
      // POST /auth/login
      ..post('/login', (Request request) async {
        // Parse and validate using DTO
        final requestBody = await request.readAsString();
        if (requestBody.isEmpty) {
          throw BadRequestException('Request body cannot be empty.');
        }
        final jsonBody = jsonDecode(requestBody) as Map<String, dynamic>;
        final loginDto = LoginRequestDto.fromJson(jsonBody);

        final token = await _authService.login(loginDto.username, loginDto.password);
        final responseDto = LoginResponseDto(token: token);
        
        return Response.ok(
          jsonEncode(responseDto.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      })
      
      // POST /auth/register
      ..post('/register', (Request request) async {
        // Parse and validate using DTO
        final requestBody = await request.readAsString();
        if (requestBody.isEmpty) {
          throw BadRequestException('Request body cannot be empty.');
        }
        final jsonBody = jsonDecode(requestBody) as Map<String, dynamic>;
        final registerDto = RegisterRequestDto.fromJson(jsonBody);

        try {
          final user = await _authService.register(
            registerDto.username,
            registerDto.password,
            role: registerDto.role ?? 'user',
          );
          
          final responseDto = UserResponseDto.fromDomain(user);
          return Response(
            201, // Created
            body: jsonEncode(responseDto.toJson()),
            headers: {'Content-Type': 'application/json'},
          );
        } on BadRequestException {
          // Re-throw specific exceptions for consistent error handling
          rethrow;
        } catch (e) {
          throw InternalServerException('Failed to register user');
        }
      })
      
      // POST /auth/refresh
      ..post('/refresh', (Request request) async {
        // Parse and validate using DTO
        final requestBody = await request.readAsString();
        if (requestBody.isEmpty) {
          throw BadRequestException('Request body cannot be empty.');
        }
        final jsonBody = jsonDecode(requestBody) as Map<String, dynamic>;
        final refreshDto = RefreshTokenRequestDto.fromJson(jsonBody);

        try {
          final newToken = await _authService.refreshToken(refreshDto.refreshToken);
          final responseDto = LoginResponseDto(token: newToken);
          
          return Response.ok(
            jsonEncode(responseDto.toJson()),
            headers: {'Content-Type': 'application/json'},
          );
        } on UnauthorizedException {
          rethrow;
        } catch (e) {
          throw InternalServerException('Failed to refresh token');
        }
      })
      
      // POST /auth/logout
      ..post('/logout', (Request request) async {
        // Parse and validate using DTO
        final requestBody = await request.readAsString();
        if (requestBody.isEmpty) {
          throw BadRequestException('Request body cannot be empty.');
        }
        final jsonBody = jsonDecode(requestBody) as Map<String, dynamic>;
        final refreshDto = RefreshTokenRequestDto.fromJson(jsonBody);

        try {
          final success = await _authService.logout(refreshDto.refreshToken);
          
          if (success) {
            return Response.ok(
              jsonEncode({'message': 'Successfully logged out'}),
              headers: {'Content-Type': 'application/json'},
            );
          } else {
            return Response.ok(
              jsonEncode({'message': 'No active session found'}),
              headers: {'Content-Type': 'application/json'},
            );
          }
        } catch (e) {
          throw InternalServerException('Failed to logout');
        }
      })
      
      // GET /auth/verify
      ..get('/verify', (Request request) async {
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          throw UnauthorizedException('Missing or invalid authorization header');
        }
        
        final token = authHeader.substring(7); // Remove 'Bearer ' prefix
        
        try {
          final user = await _authService.verifyToken(token);
          final responseDto = UserResponseDto.fromDomain(user);
          
          return Response.ok(
            jsonEncode(responseDto.toJson()),
            headers: {'Content-Type': 'application/json'},
          );
        } on UnauthorizedException {
          rethrow;
        } catch (e) {
          throw UnauthorizedException('Invalid token');
        }
      });

    return router;
  }
}
