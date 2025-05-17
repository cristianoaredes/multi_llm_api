/// Representa informações sobre um modelo de IA disponível na API.
///
/// Este DTO é usado para retornar informações sobre os modelos disponíveis
/// para o cliente.
class ModelInfoDto {
  /// Cria uma nova instância de ModelInfoDto.
  ModelInfoDto({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.capabilities,
    required this.maxTokens,
    required this.temperature,
    this.defaultModel = false,
  });

  /// Identificador único do modelo
  final String id;

  /// Nome amigável do modelo
  final String name;

  /// Provedor do modelo (ex: "gemini", "openrouter", "openai")
  final String provider;

  /// Descrição curta do modelo
  final String description;

  /// Lista de capacidades do modelo
  final List<String> capabilities;

  /// Máximo de tokens que o modelo suporta para resposta
  final int maxTokens;

  /// Temperatura padrão do modelo
  final double temperature;

  /// Indica se este é o modelo padrão
  final bool defaultModel;

  /// Converte o DTO para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'description': description,
      'capabilities': capabilities,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'default_model': defaultModel,
    };
  }
}

/// Lista de modelos disponíveis como resposta do endpoint /api/v1/generate/models
class ModelsListDto {
  /// Cria uma nova instância de ModelsListDto.
  ModelsListDto({
    required this.models,
    required this.totalCount,
    required this.defaultModelId,
  });

  /// Lista de modelos disponíveis
  final List<ModelInfoDto> models;

  /// Total de modelos disponíveis
  final int totalCount;

  /// ID do modelo padrão
  final String defaultModelId;

  /// Converte o DTO para JSON
  Map<String, dynamic> toJson() {
    return {
      'models': models.map((model) => model.toJson()).toList(),
      'total_count': totalCount,
      'default_model_id': defaultModelId,
    };
  }
}
