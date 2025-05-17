import 'package:multi_llm_api/features/auth/data/repositories/in_memory_refresh_token_repository.dart';
import 'package:multi_llm_api/features/auth/data/repositories/in_memory_user_repository.dart';
import 'package:multi_llm_api/features/auth/domain/auth_service.dart';
import 'package:multi_llm_api/features/auth/domain/auth_service_interface.dart';
import 'package:multi_llm_api/features/auth/domain/interfaces/i_refresh_token_repository.dart';
import 'package:multi_llm_api/features/auth/domain/interfaces/i_user_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';

void setupAuthInjector(GetIt injector) {
  final log = Logger('AuthInjector');

  // Use in-memory repositories for development
  log.info('Using in-memory repositories for development');
  injector.registerLazySingleton<IUserRepository>(InMemoryUserRepository.new);
  log.info('Registered InMemoryUserRepository');
  
  injector.registerLazySingleton<IRefreshTokenRepository>(
    InMemoryRefreshTokenRepository.new,
  );
  log.info('Registered InMemoryRefreshTokenRepository');

  // Register the auth service
  injector.registerLazySingleton<IAuthService>(
    () => AuthService(
      injector<IUserRepository>(),
      injector<IRefreshTokenRepository>(),
    ),
  );
  log.info('Registered AuthService');
}
