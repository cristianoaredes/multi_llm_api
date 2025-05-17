import 'dart:async';
import 'package:multi_llm_api/core/config/env_config.dart';
import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:multi_llm_api/core/services/cache_service.dart';
import 'package:multi_llm_api/features/generative/domain/interfaces/i_generative_service.dart';
import 'package:crypto/crypto.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logging/logging.dart';
import 'dart:convert';

/// Serviço para interagir com a API Gemini para geração de texto e chat.
class GenerativeService implements IGenerativeService {
  /// Initializes the GenerativeService, attempting to configure the Gemini model.
  GenerativeService() {
    try {
      final apiKey = EnvConfig.geminiApiKey;
      if (apiKey == 'SUA_CHAVE_API_AQUI' || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY não configurada corretamente no .env');
      }

      // Use the model name from environment configuration
      final modelName = EnvConfig.geminiModel;
      _log.info('Usando modelo Gemini: $modelName');

      // Configure safety settings from environment
      final safetySettings = _configureSafetySettings();

      // Create the model with configuration from environment
      _model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: EnvConfig.geminiMaxTokens,
          temperature: EnvConfig.geminiTemperature,
        ),
        safetySettings: safetySettings,
      );

      // Initialize the cache
      _textCache = CacheService<String, String>(
        maxSize: 100, // Cache up to 100 responses
        ttlSeconds: 3600, // Cache for 1 hour
      );

      _chatCache = CacheService<String, String>(
        maxSize: 50, // Cache up to 50 chat responses
        ttlSeconds: 1800, // Cache for 30 minutes
      );

      _isAvailable = true;
      _log.info('GenerativeModel inicializado com sucesso.');
    } catch (e, s) {
      _log.warning(
        'Não foi possível inicializar o GenerativeModel. O serviço funcionará '
        'em modo de simulação.',
        e,
        s,
      );
      _isAvailable = false;
    }
  }

  /// Configure safety settings based on environment configuration
  List<SafetySetting> _configureSafetySettings() {
    return [
      SafetySetting(
        HarmCategory.harassment,
        _getThresholdFromString(EnvConfig.geminiSafetyHarassment),
      ),
      SafetySetting(
        HarmCategory.hateSpeech,
        _getThresholdFromString(EnvConfig.geminiSafetyHateSpeech),
      ),
      SafetySetting(
        HarmCategory.sexuallyExplicit,
        _getThresholdFromString(EnvConfig.geminiSafetySexuallyExplicit),
      ),
      SafetySetting(
        HarmCategory.dangerousContent,
        _getThresholdFromString(EnvConfig.geminiSafetyDangerous),
      ),
    ];
  }

  /// Convert string threshold configuration to enum value
  HarmBlockThreshold _getThresholdFromString(String threshold) {
    switch (threshold.toUpperCase()) {
      case 'BLOCK_NONE':
        return HarmBlockThreshold.none;
      case 'BLOCK_LOW_AND_ABOVE':
        return HarmBlockThreshold.low;
      case 'BLOCK_MEDIUM_AND_ABOVE':
        return HarmBlockThreshold.medium;
      case 'BLOCK_HIGH_AND_ABOVE':
      case 'BLOCK_ONLY_HIGH':
        return HarmBlockThreshold.high;
      default:
        _log.warning(
            'Threshold inválido: $threshold, usando MEDIUM_AND_ABOVE como padrão');
        return HarmBlockThreshold.medium;
    }
  }

  final Logger _log = Logger('GenerativeService');
  GenerativeModel? _model;
  bool _isAvailable = false;
  late final CacheService<String, String> _textCache;
  late final CacheService<String, String> _chatCache;

  /// Returns the current model name being used
  String get modelName => _isAvailable && _model != null
      ? EnvConfig.geminiModel
      : 'Simulação (modelo não disponível)';

  /// Returns the current model configuration
  Map<String, dynamic> get modelConfig => {
        'model': modelName,
        'maxTokens': EnvConfig.geminiMaxTokens,
        'temperature': EnvConfig.geminiTemperature,
        'isAvailable': _isAvailable,
        'streamingEnabled': EnvConfig.geminiEnableStreaming,
        'safetySettings': {
          'harassment': EnvConfig.geminiSafetyHarassment,
          'hateSpeech': EnvConfig.geminiSafetyHateSpeech,
          'sexuallyExplicit': EnvConfig.geminiSafetySexuallyExplicit,
          'dangerous': EnvConfig.geminiSafetyDangerous,
        },
        'cacheStats': {
          'textCacheSize': _textCache.size,
          'chatCacheSize': _chatCache.size,
        },
      };

  /// Generates a cache key for a prompt
  String _generateTextCacheKey(String prompt) {
    final normalized = prompt.trim().toLowerCase();
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a cache key for a chat
  String _generateChatCacheKey(
      List<Map<String, String>> history, String newMessage) {
    final buffer = StringBuffer();

    // Add history to the buffer
    for (final message in history) {
      buffer.write('${message['role']}:${message['text']};');
    }

    // Add new message to the buffer
    buffer.write('user:$newMessage');

    // Generate hash
    final bytes = utf8.encode(buffer.toString().trim().toLowerCase());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<String> generateText(String prompt) async {
    if (prompt.trim().isEmpty) {
      throw BadRequestException('O prompt não pode estar vazio.');
    }

    // Check if the response is in the cache
    final cacheKey = _generateTextCacheKey(prompt);
    final cachedResponse = _textCache.get(cacheKey);

    if (cachedResponse != null) {
      _log.fine('Cache hit for prompt: "${_truncatePrompt(prompt)}"');
      return cachedResponse;
    }

    if (!_isAvailable || _model == null) {
      _log.info(
        'Usando modo de simulação para gerar resposta ao prompt: '
        '"${_truncatePrompt(prompt)}"',
      );
      final mockResponse = _generateMockResponse(prompt);

      // Cache the mock response
      _textCache.put(cacheKey, mockResponse);

      return mockResponse;
    }

    try {
      _log.fine('Gerando texto para prompt: "${_truncatePrompt(prompt)}"');
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      _log.fine('Resposta recebida da API Gemini.');
      if (response.text == null) {
        _log.warning('A API Gemini retornou um texto de resposta nulo.');
        final reason =
            response.promptFeedback?.blockReason?.name ?? 'desconhecido';
        final reasonMessage = response.promptFeedback?.blockReasonMessage ??
            'Nenhuma razão específica fornecida.';
        throw InternalServerException(
          'Falha ao gerar texto. Motivo: $reason. $reasonMessage',
        );
      }

      // Cache the response
      _textCache.put(cacheKey, response.text!);

      return response.text!;
    } on GenerativeAIException catch (e) {
      _log.severe('GenerativeAIException ao gerar texto', e);
      throw InternalServerException(
        'Erro ao comunicar com o serviço de IA Generativa: ${e.message}',
      );
    } catch (e, s) {
      _log.severe('Erro inesperado ao gerar texto', e, s);
      throw InternalServerException(
        'Ocorreu um erro inesperado durante a geração de texto.',
      );
    }
  }

  @override
  Stream<String> generateTextStream(String prompt) async* {
    if (prompt.trim().isEmpty) {
      throw BadRequestException('O prompt não pode estar vazio.');
    }

    if (!EnvConfig.geminiEnableStreaming) {
      // If streaming is disabled, use the regular method and yield once
      yield await generateText(prompt);
      return;
    }

    if (!_isAvailable || _model == null) {
      _log.info(
        'Usando modo de simulação para gerar resposta ao prompt: '
        '"${_truncatePrompt(prompt)}"',
      );
      yield _generateMockResponse(prompt);
      return;
    }

    try {
      _log.fine(
          'Gerando texto em streaming para prompt: "${_truncatePrompt(prompt)}"');
      final content = [Content.text(prompt)];

      final responseStream = _model!.generateContentStream(content);

      final buffer = StringBuffer();

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          buffer.write(chunk.text);
          yield chunk.text ?? '';
        }
      }

      // Cache the complete response
      final fullResponse = buffer.toString();
      if (fullResponse.isNotEmpty) {
        final cacheKey = _generateTextCacheKey(prompt);
        _textCache.put(cacheKey, fullResponse);
      }
    } on GenerativeAIException catch (e) {
      _log.severe('GenerativeAIException ao gerar texto em streaming', e);
      throw InternalServerException(
        'Erro ao comunicar com o serviço de IA Generativa: ${e.message}',
      );
    } catch (e, s) {
      _log.severe('Erro inesperado ao gerar texto em streaming', e, s);
      throw InternalServerException(
        'Ocorreu um erro inesperado durante a geração de texto em streaming.',
      );
    }
  }

  @override
  Future<String> continueChat(
    List<Map<String, String>> history,
    String newMessage,
  ) async {
    if (newMessage.trim().isEmpty) {
      throw BadRequestException('A nova mensagem não pode estar vazia.');
    }
    // Validar formato básico do histórico
    if (history.any(
      (msg) =>
          !msg.containsKey('role') ||
          !msg.containsKey('text') ||
          (msg['role'] != 'user' && msg['role'] != 'model'),
    )) {
      throw BadRequestException('Formato inválido para o histórico do chat.');
    }

    // Check if the response is in the cache
    final cacheKey = _generateChatCacheKey(history, newMessage);
    final cachedResponse = _chatCache.get(cacheKey);

    if (cachedResponse != null) {
      _log.fine('Cache hit for chat: "${_truncatePrompt(newMessage)}"');
      return cachedResponse;
    }

    if (!_isAvailable || _model == null) {
      _log.info(
        'Usando modo de simulação para continuar chat. Última mensagem: '
        '"${_truncatePrompt(newMessage)}"',
      );
      final mockResponse = _generateMockChatResponse(newMessage);

      // Cache the mock response
      _chatCache.put(cacheKey, mockResponse);

      return mockResponse;
    }

    try {
      _log.fine(
          'Continuando chat. Última mensagem: "${_truncatePrompt(newMessage)}"');

      // Converter histórico para o formato Content
      final historyContent = history.map((msg) {
        final role = msg['role']!;
        final text = msg['text']!;
        return Content(role, [TextPart(text)]);
      }).toList();

      final chat = _model!.startChat(history: historyContent);
      final response = await chat.sendMessage(Content.text(newMessage));

      _log.fine('Resposta recebida da API Gemini para o chat.');
      if (response.text == null) {
        _log.warning(
            'A API Gemini retornou um texto de resposta nulo para o chat.');
        final reason =
            response.promptFeedback?.blockReason?.name ?? 'desconhecido';
        final reasonMessage = response.promptFeedback?.blockReasonMessage ??
            'Nenhuma razão específica fornecida.';
        throw InternalServerException(
          'Falha ao gerar resposta do chat. Motivo: $reason. $reasonMessage',
        );
      }

      // Cache the response
      _chatCache.put(cacheKey, response.text!);

      return response.text!;
    } on GenerativeAIException catch (e) {
      _log.severe('GenerativeAIException ao continuar chat', e);
      throw InternalServerException(
        'Erro ao comunicar com o serviço de IA Generativa: ${e.message}',
      );
    } catch (e, s) {
      _log.severe('Erro inesperado ao continuar chat', e, s);
      throw InternalServerException(
        'Ocorreu um erro inesperado durante a continuação do chat.',
      );
    }
  }

  @override
  Stream<String> continueChatStream(
    List<Map<String, String>> history,
    String newMessage,
  ) async* {
    if (newMessage.trim().isEmpty) {
      throw BadRequestException('A nova mensagem não pode estar vazia.');
    }

    // Validar formato básico do histórico
    if (history.any(
      (msg) =>
          !msg.containsKey('role') ||
          !msg.containsKey('text') ||
          (msg['role'] != 'user' && msg['role'] != 'model'),
    )) {
      throw BadRequestException('Formato inválido para o histórico do chat.');
    }

    if (!EnvConfig.geminiEnableStreaming) {
      // If streaming is disabled, use the regular method and yield once
      yield await continueChat(history, newMessage);
      return;
    }

    if (!_isAvailable || _model == null) {
      _log.info(
        'Usando modo de simulação para continuar chat. Última mensagem: '
        '"${_truncatePrompt(newMessage)}"',
      );
      yield _generateMockChatResponse(newMessage);
      return;
    }

    try {
      _log.fine(
          'Continuando chat em streaming. Última mensagem: "${_truncatePrompt(newMessage)}"');

      // Converter histórico para o formato Content
      final historyContent = history.map((msg) {
        final role = msg['role']!;
        final text = msg['text']!;
        return Content(role, [TextPart(text)]);
      }).toList();

      final chat = _model!.startChat(history: historyContent);
      final responseStream = chat.sendMessageStream(Content.text(newMessage));

      final buffer = StringBuffer();

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          buffer.write(chunk.text);
          yield chunk.text ?? '';
        }
      }

      // Cache the complete response
      final fullResponse = buffer.toString();
      if (fullResponse.isNotEmpty) {
        final cacheKey = _generateChatCacheKey(history, newMessage);
        _chatCache.put(cacheKey, fullResponse);
      }
    } on GenerativeAIException catch (e) {
      _log.severe('GenerativeAIException ao continuar chat em streaming', e);
      throw InternalServerException(
        'Erro ao comunicar com o serviço de IA Generativa: ${e.message}',
      );
    } catch (e, s) {
      _log.severe('Erro inesperado ao continuar chat em streaming', e, s);
      throw InternalServerException(
        'Ocorreu um erro inesperado durante a continuação do chat em streaming.',
      );
    }
  }

  /// Trunca o prompt para log
  String _truncatePrompt(String prompt, {int maxLength = 50}) {
    return prompt.length > maxLength
        ? '${prompt.substring(0, maxLength)}...'
        : prompt;
  }

  /// Gera uma resposta simulada quando a API não está disponível
  String _generateMockResponse(String prompt) {
    return '''
Resposta Simulada: 

Este é um texto gerado localmente pois a API Gemini não está configurada.
Para utilizar a API Gemini real, obtenha uma chave e configure no arquivo .env.

Seu prompt foi: "${_truncatePrompt(prompt, maxLength: 100)}"
''';
  }

  /// Gera uma resposta simulada para chat quando a API não está disponível
  String _generateMockChatResponse(String newMessage) {
    return '''
Resposta Simulada (Chat): 

Recebi sua mensagem: "${_truncatePrompt(newMessage, maxLength: 100)}"

Lembre-se que estou em modo de simulação pois a API Gemini não está configurada.
''';
  }

  /// Clears the cache
  void clearCache() {
    _textCache.clear();
    _chatCache.clear();
    _log.info('Cache limpo.');
  }
}
