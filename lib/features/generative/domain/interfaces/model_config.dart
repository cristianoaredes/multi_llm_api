import 'package:api_dart/core/config/env_config.dart';

/// Representa a configuração de um modelo de IA generativa.
///
/// Esta classe contém todas as configurações necessárias para invocar um modelo
/// de IA generativa, como nome do modelo, tokens máximos, temperatura e
/// configurações de segurança.
class ModelConfig {
  /// Cria uma nova instância de ModelConfig.
  ModelConfig({
    required this.name,
    required this.provider,
    required this.maxTokens,
    required this.temperature,
    this.safetySettings = const {},
    this.enableStreaming = true,
  });

  /// Cria uma configuração de modelo a partir do ambiente atual.
  ///
  /// Dependendo do provedor configurado em AI_PROVIDER, retorna a configuração
  /// apropriada para Gemini ou OpenRouter.
  factory ModelConfig.fromEnvironment() {
    final provider = EnvConfig.aiProvider.toLowerCase();

    switch (provider) {
      case 'gemini':
        return ModelConfig(
          name: EnvConfig.geminiModel,
          provider: 'gemini',
          maxTokens: EnvConfig.geminiMaxTokens,
          temperature: EnvConfig.geminiTemperature,
          safetySettings: {
            'harassment': EnvConfig.geminiSafetyHarassment,
            'hate_speech': EnvConfig.geminiSafetyHateSpeech,
            'sexually_explicit': EnvConfig.geminiSafetySexuallyExplicit,
            'dangerous': EnvConfig.geminiSafetyDangerous,
          },
          enableStreaming: EnvConfig.geminiEnableStreaming,
        );

      case 'openrouter':
        return ModelConfig(
          name: EnvConfig.openRouterModel,
          provider: 'openrouter',
          maxTokens: EnvConfig.openRouterMaxTokens,
          temperature: EnvConfig.openRouterTemperature,
          enableStreaming: EnvConfig.openRouterEnableStreaming,
        );

      default:
        throw ArgumentError('Provedor de IA não suportado: $provider');
    }
  }

  /// Nome do modelo (ex: "gemini-1.5-flash")
  final String name;

  /// Provedor do modelo (ex: "gemini", "openrouter")
  final String provider;

  /// Número máximo de tokens da resposta
  final int maxTokens;

  /// Temperatura para geração de texto (0.0 - 1.0)
  final double temperature;

  /// Configurações de segurança específicas do provedor
  final Map<String, dynamic> safetySettings;

  /// Se o streaming de respostas está habilitado
  final bool enableStreaming;

  /// Converte a configuração em um mapa
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'provider': provider,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'safety_settings': safetySettings,
      'enable_streaming': enableStreaming,
    };
  }

  @override
  String toString() {
    return 'ModelConfig(name: $name, provider: $provider, maxTokens: $maxTokens, '
        'temperature: $temperature, enableStreaming: $enableStreaming)';
  }
}
