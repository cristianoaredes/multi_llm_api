import 'package:api_dart/features/auth/auth_injector.dart';
import 'package:api_dart/features/generative/generative_injector.dart';
import 'package:get_it/get_it.dart';

/// Global instance of the GetIt service locator.
final GetIt injector = GetIt.instance;

/// Sets up the dependency injection container.
///
/// Registers services, repositories, and other dependencies used throughout
/// the application.
Future<void> setupInjector() async {
  // Modular DI setup for each feature
  setupAuthInjector(injector);
  setupGenerativeInjector(injector);

  // Add other dependencies here (e.g., HTTP clients, database connections)
}
