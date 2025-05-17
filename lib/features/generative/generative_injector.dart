import 'package:api_dart/core/config/env_config.dart';
import 'package:api_dart/features/generative/domain/generative_service.dart';
import 'package:api_dart/features/generative/domain/interfaces/i_generative_service.dart';
import 'package:api_dart/features/generative/domain/openrouter_service.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';

/// Configura as injeções de dependência para o módulo generativo.
void setupGenerativeInjector(GetIt injector) {
  final Logger _log = Logger('GenerativeInjector');

  // Determinar qual provedor de IA generativa usar com base na configuração
  final provider = EnvConfig.aiProvider.toLowerCase();

  _log.info('Configurando serviço generativo com provedor: $provider');

  // Registrar a implementação apropriada com base no provedor configurado
  if (provider == 'openrouter') {
    _log.info('Usando OpenRouter como provedor de IA generativa');
    injector.registerLazySingleton<IGenerativeService>(OpenRouterService.new);
  } else {
    // Padrão é o Gemini
    _log.info('Usando Gemini como provedor de IA generativa');
    injector.registerLazySingleton<IGenerativeService>(GenerativeService.new);
  }
}
