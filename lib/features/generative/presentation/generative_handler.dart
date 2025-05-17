import 'dart:async';
import 'dart:convert';

// Sorted Imports: dart:, package:api_dart, package:shelf
import 'package:api_dart/core/di/injector.dart';
import 'package:api_dart/core/error/app_exception.dart';
import 'package:api_dart/features/generative/domain/interfaces/i_generative_service.dart';
import 'package:api_dart/features/generative/presentation/dtos/chat_request_dto.dart'; // Import Chat DTOs
import 'package:api_dart/features/generative/presentation/dtos/chat_response_dto.dart'; // Import Chat DTOs
import 'package:api_dart/features/generative/presentation/dtos/generate_text_request_dto.dart';
import 'package:api_dart/features/generative/presentation/dtos/generate_text_response_dto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Handles HTTP requests for the generative AI endpoints (e.g., text
/// generation).
class GenerativeHandler {
  // Inject the interface instead of the concrete class
  final IGenerativeService _generativeService = injector<IGenerativeService>();

  /// Provides the configured router for generative AI routes.
  Router get router {
    final router = Router()

      // GET /generate/info
      ..get('/info', (Request request) async {
        final modelInfo = {
          'name': _generativeService.modelName,
          'config': _generativeService.modelConfig,
        };

        return Response.ok(
          jsonEncode(modelInfo),
          headers: {'Content-Type': 'application/json'},
        );
      })

      // POST /generate/cache/clear
      ..post('/cache/clear', (Request request) async {
        _generativeService.clearCache();

        return Response.ok(
          jsonEncode(
              {'success': true, 'message': 'Cache cleared successfully'}),
          headers: {'Content-Type': 'application/json'},
        );
      })

      // POST /generate/text
      ..post('/text', (Request request) async {
        // Parse and validate using DTO
        final requestBody = await request.readAsString();
        if (requestBody.isEmpty) {
          throw BadRequestException('Request body cannot be empty.');
        }
        final jsonBody = jsonDecode(requestBody) as Map<String, dynamic>;
        final requestDto = GenerateTextRequestDto.fromJson(jsonBody);

        final generatedText =
            await _generativeService.generateText(requestDto.prompt);

        final responseDto =
            GenerateTextResponseDto(generatedText: generatedText);
        return Response.ok(
          jsonEncode(responseDto.toJson()), // Encode DTO
          headers: {'Content-Type': 'application/json'}, // Add comma
        );
      })

      // POST /generate/text/stream
      ..post('/text/stream', (Request request) async {
        // Parse and validate using DTO
        final requestBody = await request.readAsString();
        if (requestBody.isEmpty) {
          throw BadRequestException('Request body cannot be empty.');
        }
        final jsonBody = jsonDecode(requestBody) as Map<String, dynamic>;
        final requestDto = GenerateTextRequestDto.fromJson(jsonBody);

        // Create a stream controller for the text chunks
        final streamController = StreamController<String>()

          // Add the SSE prefix and content-type
          ..add('data: {"status":"started"}\n\n');

        // Handle the stream of text chunks
        _generativeService.generateTextStream(requestDto.prompt).listen(
          (textChunk) {
            // Format each chunk as a Server-Sent Event
            streamController.add('data: {"chunk":"$textChunk"}\n\n');
          },
          onError: (Object error) {
            streamController
              ..add('data: {"error":"$error"}\n\n')
              ..close();
          },
          onDone: () {
            streamController
              ..add('data: {"status":"done"}\n\n')
              ..close();
          },
        );

        // Return the streamed response
        return Response.ok(
          streamController.stream,
          headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        );
      })

      // POST /generate/chat
      ..post('/chat', (Request request) async {
        // Parse and validate using DTO
        final requestBody = await request.readAsString();
        if (requestBody.isEmpty) {
          throw BadRequestException('Request body cannot be empty.');
        }
        final jsonBody = jsonDecode(requestBody) as Map<String, dynamic>;
        final requestDto =
            ChatRequestDto.fromJson(jsonBody); // Use ChatRequestDto

        final responseText = await _generativeService.continueChat(
          requestDto.history,
          requestDto.newMessage,
        );

        final responseDto =
            ChatResponseDto(responseText: responseText); // Use ChatResponseDto
        return Response.ok(
          jsonEncode(responseDto.toJson()), // Encode DTO
          headers: {'Content-Type': 'application/json'},
        );
      })

      // POST /generate/chat/stream
      ..post('/chat/stream', (Request request) async {
        // Parse and validate using DTO
        final requestBody = await request.readAsString();
        if (requestBody.isEmpty) {
          throw BadRequestException('Request body cannot be empty.');
        }
        final jsonBody = jsonDecode(requestBody) as Map<String, dynamic>;
        final requestDto = ChatRequestDto.fromJson(jsonBody);

        // Create a stream controller for the text chunks
        final streamController = StreamController<String>()

          // Add the SSE prefix and content-type
          ..add('data: {"status":"started"}\n\n');

        // Handle the stream of text chunks
        _generativeService
            .continueChatStream(
          requestDto.history,
          requestDto.newMessage,
        )
            .listen(
          (textChunk) {
            // Format each chunk as a Server-Sent Event
            streamController.add('data: {"chunk":"$textChunk"}\n\n');
          },
          onError: (Object error) {
            streamController
              ..add('data: {"error":"$error"}\n\n')
              ..close();
          },
          onDone: () {
            streamController
              ..add('data: {"status":"done"}\n\n')
              ..close();
          },
        );

        // Return the streamed response
        return Response.ok(
          streamController.stream,
          headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        );
      });

    return router;
  }
}
