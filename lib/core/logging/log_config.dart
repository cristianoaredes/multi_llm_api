import 'dart:io'; // Import for stdout/stderr

import 'package:api_dart/core/config/env_config.dart'; // Use package import
import 'package:logging/logging.dart';


/// Configures the global logging setup for the application.
///
/// Sets the root logging level based on the `LOG_LEVEL` environment variable
/// and listens to records to print them to the console.
void setupLogging() {
  // Set the root logger level from environment variable
  Logger.root.level = EnvConfig.logLevel;

  // Configure the logger to print messages to the console
  Logger.root.onRecord.listen((record) {
    // Replace print with standard output, respecting log levels
    // Typically, a production setup might use a more sophisticated handler
    // that formats and directs logs appropriately (e.g., to stdout/stderr
    // or a file).
    final message = StringBuffer()
      ..write('${record.level.name}: ${record.time}: ')
      ..write('[${record.loggerName}] ${record.message}');

    if (record.error != null) {
      message.write('; Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      message.write('\n${record.stackTrace}');
    }

    // Use stdout or stderr based on level for better process management
    if (record.level >= Level.SEVERE) {
      stderr.writeln(message.toString());
    } else {
      stdout.writeln(message.toString());
    }
  });

  // Example of getting a logger for a specific part of the app
  // Use direct method call instead of single cascade
  Logger('AppInitialization')
      .info('Logging initialized at level ${EnvConfig.logLevel.name}');
}
