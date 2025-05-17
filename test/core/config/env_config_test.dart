import 'dart:io';

import 'package:multi_llm_api/core/config/env_config.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
// import 'package:dotenv/dotenv.dart'; // Unused import removed

// Criamos um mock da classe DotEnv para facilitar os testes
class MockEnvConfig extends EnvConfig {
  static Map<String, String> envValues = {};

  static void setEnvValues(Map<String, String> values) {
    envValues = values;
  }

  // Sobrescreve getters para usar valores de teste
  static int get serverPort {
    return int.tryParse(envValues['SERVER_PORT'] ?? '8080') ?? 8080;
  }

  static Level get logLevel {
    final levelName = envValues['LOG_LEVEL'] ?? 'INFO';
    return Level.LEVELS.firstWhere(
      (level) => level.name == levelName.toUpperCase(),
      orElse: () => Level.INFO,
    );
  }

  static String get geminiApiKey {
    final key = envValues['GEMINI_API_KEY'];
    if (key == null || key.isEmpty || key == 'SUA_CHAVE_API_AQUI') {
      // Ensure formatting and comma
      throw StateError(
        'GEMINI_API_KEY não está definida ou está com valor padrão no '
        'arquivo .env.',
      );
    }
    return key;
  }
}

void main() {
  group('EnvConfig', () {
    setUp(() {
      // Configura valores padrão para teste
      MockEnvConfig.setEnvValues({
        'SERVER_PORT': '9090',
        'LOG_LEVEL': 'WARNING',
        'GEMINI_API_KEY': 'fake_test_key_1234',
      });
    });

    test('serverPort returns correct value', () {
      expect(MockEnvConfig.serverPort, equals(9090));
    });

    test('logLevel returns correct log level', () {
      expect(MockEnvConfig.logLevel, equals(Level.WARNING));
    });

    test('geminiApiKey returns correct API key', () {
      expect(MockEnvConfig.geminiApiKey, equals('fake_test_key_1234'));
    });

    test('serverPort returns default value', () {
      MockEnvConfig.setEnvValues({
        'LOG_LEVEL': 'INFO',
        'GEMINI_API_KEY': 'fake_test_key_1234',
      });

      expect(MockEnvConfig.serverPort, equals(8080));
    });

    test('logLevel returns default value', () {
      MockEnvConfig.setEnvValues({
        'SERVER_PORT': '9090',
        'GEMINI_API_KEY': 'fake_test_key_1234',
      });

      expect(MockEnvConfig.logLevel, equals(Level.INFO));
    });

    test('geminiApiKey throws when not defined', () {
      // Shortened
      MockEnvConfig.setEnvValues({
        'SERVER_PORT': '9090',
        'LOG_LEVEL': 'INFO',
      });

      expect(() => MockEnvConfig.geminiApiKey, throwsStateError);
    });

    test('geminiApiKey throws for default value', () {
      // Shortened
      MockEnvConfig.setEnvValues({
        'SERVER_PORT': '9090',
        'LOG_LEVEL': 'INFO',
        'GEMINI_API_KEY': 'SUA_CHAVE_API_AQUI',
      });

      expect(() => MockEnvConfig.geminiApiKey, throwsStateError);
    });

    // Teste com arquivo .env real (integração)
    test('loadEnv loads variables from .env file', () async {
      // Cria um arquivo .env temporário para teste
      final tempFile = File('.env.test');
      await tempFile.writeAsString('''
SERVER_PORT=9595
LOG_LEVEL=FINE
GEMINI_API_KEY=fake_test_key_for_file_tests
''');

      // Faz backup do arquivo .env original
      final envFile = File('.env');
      final backupFile = File('.env.backup'); // Define backupFile here
      // Keep async for setup before async loadEnv
      if (await envFile.exists()) {
        await envFile.rename('.env.backup');
      }

      // Copia o arquivo de teste para .env
      await tempFile.copy('.env'); // Keep async before async loadEnv

      try {
        // Carrega com EnvConfig real
        await EnvConfig.loadEnv(); // Keep await

        // Testa valores
        expect(EnvConfig.serverPort, equals(9595));
        expect(EnvConfig.logLevel, equals(Level.FINE));
        expect(EnvConfig.geminiApiKey, equals('fake_test_key_for_file_tests'));
      } finally {
        // Limpa os arquivos temporários (Use sync in finally)
        if (tempFile.existsSync()) {
          // Use sync
          tempFile.deleteSync(); // Use sync
        }

        // Restaura o arquivo .env original (Use sync in finally)
        if (backupFile.existsSync()) {
          // Use sync
          backupFile.renameSync('.env'); // Use sync
        } // Add trailing comma
      }
    });
  });
}
