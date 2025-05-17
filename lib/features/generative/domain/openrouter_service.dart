import 'dart:async';
import 'dart:convert';
import 'package:multi_llm_api/core/config/env_config.dart';
import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:multi_llm_api/core/services/cache_service.dart';
import 'package:multi_llm_api/features/generative/domain/interfaces/i_generative_service.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Serviço para interagir com o OpenRouter para geração de texto e chat.
class OpenRouterService implements IGenerativeService {
  /// Initializes the OpenRouterService
  OpenRouterService() {
    try {
      final apiKey = EnvConfig.openRouterApiKey;
      final baseUrl = EnvConfig.openRouterBaseUrl;

      if (apiKey.isEmpty) {
        _log.warning(
            'OpenRouter API key não configurada. Funcionando em modo de simulação.');
        _simulationMode = true;
      } else {
        _log.info('OpenRouter service inicializado com sucesso.');
        _apiKey = apiKey;
        _baseUrl = baseUrl;
        _simulationMode = false;
      }

      _model = EnvConfig.openRouterModel;
      _maxTokens = EnvConfig.openRouterMaxTokens;
      _temperature = EnvConfig.openRouterTemperature;
      _enableStreaming = EnvConfig.openRouterEnableStreaming;
    } catch (e) {
      _log.severe(
          'Não foi possível inicializar o OpenRouterService. O serviço funcionará em modo de simulação.',
          e);
      _simulationMode = true;
    }
  }

  final Logger _log = Logger('OpenRouterService');
  final CacheService<String, String> _cache = CacheService<String, String>(
    maxSize: 100,
    ttlSeconds: 3600,
  );

  late final String _apiKey;
  late final String _baseUrl;
  late final String _model;
  late final int _maxTokens;
  late final double _temperature;
  late final bool _enableStreaming;
  late final bool _simulationMode;

  /// Generates text from a prompt
  @override
  Future<String> generateText(String prompt) async {
    if (_simulationMode) {
      _log.info('Modo de simulação: gerando texto para prompt: $prompt');
      return 'Resposta simulada do OpenRouter para: $prompt\n\nEste é um texto gerado em modo de simulação, pois o OpenRouter não está configurado corretamente. Configure a chave de API do OpenRouter no arquivo .env para utilizar o serviço real.';
    }

    try {
      // Cache check
      final cacheKey = _generateCacheKey('text', prompt, {});
      final cachedResponse = _cache.get(cacheKey);
      if (cachedResponse != null) {
        _log.info(
            'Cache hit for text generation with prompt: ${prompt.substring(0, prompt.length > 20 ? 20 : prompt.length)}...');
        return cachedResponse;
      }

      final url = '$_baseUrl/chat/completions';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'HTTP-Referer': 'https://api-dart.example.com',
        'X-Title': 'API-Dart Demo'
      };

      // Prepare the request body
      final requestBody = <String, dynamic>{
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': _maxTokens,
        'temperature': _temperature,
        'stream': false
      };

      _log.info('Sending text generation request to OpenRouter API');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        final text = content is String ? content : content.toString();

        // Save to cache
        _cache.put(cacheKey, text);

        return text;
      } else {
        _log.severe(
            'OpenRouter API error: ${response.statusCode} - ${response.body}');
        throw BadRequestException(
            'Erro ao gerar texto: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error generating text', e);
      if (e is AppException) rethrow;
      throw InternalServerException(
          'Erro interno ao gerar texto: ${e.toString()}');
    }
  }

  /// Generates text with streaming response
  @override
  Stream<String> generateTextStream(String prompt) async* {
    if (_simulationMode) {
      _log.info(
          'Modo de simulação: gerando stream de texto para prompt: $prompt');

      // Simulate streaming with delays
      final simulatedResponse =
          'Resposta simulada do OpenRouter para: $prompt\n\nEste é um texto gerado em modo de simulação, pois o OpenRouter não está configurado corretamente. Configure a chave de API do OpenRouter no arquivo .env para utilizar o serviço real.';

      final words = simulatedResponse.split(' ');
      for (var i = 0; i < words.length; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        yield words[i] + (i < words.length - 1 ? ' ' : '');
      }
      return;
    }

    if (!_enableStreaming) {
      final fullResponse = await generateText(prompt);
      yield fullResponse;
      return;
    }

    try {
      final url = '$_baseUrl/chat/completions';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'HTTP-Referer': 'https://api-dart.example.com',
        'X-Title': 'API-Dart Demo',
        'Accept': 'text/event-stream',
      };

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': _maxTokens,
        'temperature': _temperature,
        'stream': true
      };

      _log.info('Sending streaming text generation request to OpenRouter API');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Process the streaming response
        final streamedResponse = response.body.split('\n');
        var fullText = '';

        for (var line in streamedResponse) {
          if (line.startsWith('data:')) {
            line = line.substring(5).trim();
            if (line == '[DONE]') continue;

            try {
              final jsonData = jsonDecode(line);
              final deltaContent = jsonData['choices'][0]['delta']['content'];
              if (deltaContent != null) {
                final delta = deltaContent is String
                    ? deltaContent
                    : deltaContent.toString();
                fullText += delta;
                yield delta;
              }
            } catch (e) {
              _log.warning('Error parsing streaming response line: $line', e);
            }
          }
        }

        // Cache the full response
        final cacheKey = _generateCacheKey('text', prompt, {});
        _cache.put(cacheKey, fullText);
      } else {
        _log.severe(
            'OpenRouter API error: ${response.statusCode} - ${response.body}');
        throw BadRequestException(
            'Erro ao gerar texto em streaming: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error generating text stream', e);
      if (e is AppException) rethrow;
      throw InternalServerException(
          'Erro interno ao gerar texto em streaming: ${e.toString()}');
    }
  }

  /// Continues a chat conversation
  @override
  Future<String> continueChat(
    List<Map<String, String>> history,
    String newMessage,
  ) async {
    if (_simulationMode) {
      _log.info(
          'Modo de simulação: continuando conversa com ${history.length} mensagens');
      return 'Resposta simulada do OpenRouter para a conversa.\n\nÚltima mensagem: $newMessage\n\nEste é um texto gerado em modo de simulação, pois o OpenRouter não está configurado corretamente. Configure a chave de API do OpenRouter no arquivo .env para utilizar o serviço real.';
    }

    try {
      // Format the conversation history for OpenRouter API
      final messages = <Map<String, String>>[];

      // Convert the history format
      for (final msg in history) {
        messages.add({
          'role': msg['role'] == 'model' ? 'assistant' : 'user',
          'content': msg['text'] ?? ''
        });
      }

      // Add the new message
      messages.add({'role': 'user', 'content': newMessage});

      // Generate cache key based on entire conversation
      final cacheKey = _generateCacheKey('chat', jsonEncode(messages), {});
      final cachedResponse = _cache.get(cacheKey);
      if (cachedResponse != null) {
        _log.info('Cache hit for chat continuation');
        return cachedResponse;
      }

      final url = '$_baseUrl/chat/completions';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'HTTP-Referer': 'https://api-dart.example.com',
        'X-Title': 'API-Dart Demo'
      };

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'model': _model,
        'messages': messages,
        'max_tokens': _maxTokens,
        'temperature': _temperature,
        'stream': false
      };

      _log.info('Sending chat continuation request to OpenRouter API');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        final text = content is String ? content : content.toString();

        // Save to cache
        _cache.put(cacheKey, text);

        return text;
      } else {
        _log.severe(
            'OpenRouter API error: ${response.statusCode} - ${response.body}');
        throw BadRequestException(
            'Erro ao continuar chat: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error continuing chat', e);
      if (e is AppException) rethrow;
      throw InternalServerException(
          'Erro interno ao continuar chat: ${e.toString()}');
    }
  }

  /// Continues a chat conversation with streaming response
  @override
  Stream<String> continueChatStream(
    List<Map<String, String>> history,
    String newMessage,
  ) async* {
    if (_simulationMode) {
      _log.info(
          'Modo de simulação: continuando conversa com streaming (${history.length} mensagens)');

      final simulatedResponse =
          'Resposta simulada do OpenRouter para a conversa.\n\nÚltima mensagem: $newMessage\n\nEste é um texto gerado em modo de simulação, pois o OpenRouter não está configurado corretamente. Configure a chave de API do OpenRouter no arquivo .env para utilizar o serviço real.';

      final words = simulatedResponse.split(' ');
      for (var i = 0; i < words.length; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        yield words[i] + (i < words.length - 1 ? ' ' : '');
      }
      return;
    }

    if (!_enableStreaming) {
      final fullResponse = await continueChat(history, newMessage);
      yield fullResponse;
      return;
    }

    try {
      // Format the conversation history for OpenRouter API
      final messages = <Map<String, String>>[];

      // Convert the history format
      for (final msg in history) {
        messages.add({
          'role': msg['role'] == 'model' ? 'assistant' : 'user',
          'content': msg['text'] ?? ''
        });
      }

      // Add the new message
      messages.add({'role': 'user', 'content': newMessage});

      final url = '$_baseUrl/chat/completions';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'HTTP-Referer': 'https://api-dart.example.com',
        'X-Title': 'API-Dart Demo',
        'Accept': 'text/event-stream',
      };

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'model': _model,
        'messages': messages,
        'max_tokens': _maxTokens,
        'temperature': _temperature,
        'stream': true
      };

      _log.info(
          'Sending streaming chat continuation request to OpenRouter API');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Process the streaming response
        final streamedResponse = response.body.split('\n');
        var fullText = '';

        for (var line in streamedResponse) {
          if (line.startsWith('data:')) {
            line = line.substring(5).trim();
            if (line == '[DONE]') continue;

            try {
              final jsonData = jsonDecode(line);
              final deltaContent = jsonData['choices'][0]['delta']['content'];
              if (deltaContent != null) {
                final delta = deltaContent is String
                    ? deltaContent
                    : deltaContent.toString();
                fullText += delta;
                yield delta;
              }
            } catch (e) {
              _log.warning('Error parsing streaming response line: $line', e);
            }
          }
        }

        // Cache the full response
        final cacheKey = _generateCacheKey('chat', jsonEncode(messages), {});
        _cache.put(cacheKey, fullText);
      } else {
        _log.severe(
            'OpenRouter API error: ${response.statusCode} - ${response.body}');
        throw BadRequestException(
            'Erro ao continuar chat em streaming: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error continuing chat stream', e);
      if (e is AppException) rethrow;
      throw InternalServerException(
          'Erro interno ao continuar chat em streaming: ${e.toString()}');
    }
  }

  @override
  String get modelName {
    if (_simulationMode) {
      return 'openrouter-simulation';
    }
    return _model;
  }

  @override
  Map<String, dynamic> get modelConfig {
    if (_simulationMode) {
      return {
        'mode': 'simulation',
        'base_model': _model,
        'max_tokens': _maxTokens,
        'temperature': _temperature,
        'streaming': _enableStreaming,
      };
    }
    return {
      'model': _model,
      'max_tokens': _maxTokens,
      'temperature': _temperature,
      'streaming': _enableStreaming,
    };
  }

  /// Clears the cache for this service
  @override
  void clearCache() {
    _log.info('Clearing cache for OpenRouter service');
    _cache.clear();
  }

  /// Generates a cache key for the given parameters
  String _generateCacheKey(
      String type, String input, Map<String, dynamic> options) {
    final modelName = options['model'] ?? _model;
    final maxTokens = options['max_tokens'] ?? _maxTokens;
    final temperature = options['temperature'] ?? _temperature;

    final String rawKey = '$type:$modelName:$maxTokens:$temperature:$input';
    return sha256.convert(utf8.encode(rawKey)).toString();
  }
}
