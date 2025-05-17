import 'dart:async';
import 'dart:convert';

import 'package:multi_llm_api/core/logging/log_middleware.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late Middleware middleware;
  late Handler innerHandler;
  late Handler errorHandler;
  late StreamController<LogRecord> logRecords;
  late StreamSubscription<LogRecord> subscription;

  setUp(() {
    // Create a stream controller to capture log records
    logRecords = StreamController<LogRecord>.broadcast();
    
    // Listen to log records
    subscription = Logger.root.onRecord.listen(logRecords.add);
    
    // Configure the root logger to use INFO level
    Logger.root.level = Level.INFO;
    
    // Create the log middleware
    middleware = logMiddleware();
    
    // Setup a simple inner handler that returns a 200 response
    innerHandler = (request) async {
      return Response.ok('Success');
    };
    
    // Setup a handler that throws an exception
    errorHandler = (request) async {
      throw Exception('Test error');
    };
  });

  tearDown(() async {
    // Clean up the log subscription
    await subscription.cancel();
    await logRecords.close();
  });

  group('LogMiddleware', () {
    test('logs incoming requests', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api/test'),
        headers: {'user-agent': 'Test Agent'},
      );

      final handler = middleware(innerHandler);
      await handler(request);

      // Wait for logs to be processed
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Check that the request was logged
      final logs = await logRecords.stream.take(1).toList();
      expect(logs, hasLength(1));
      expect(logs[0].message, contains('GET'));
      expect(logs[0].message, contains('/api/test'));
      expect(logs[0].message, contains('Test Agent'));
    });

    test('logs response status code', () async {
      final request = Request('GET', Uri.parse('http://localhost/api/test'));

      final handler = middleware(innerHandler);
      await handler(request);

      // Wait for logs to be processed
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Check that the response was logged
      final logs = await logRecords.stream.take(2).toList();
      expect(logs.length, greaterThanOrEqualTo(1));
      
      // Find the log entry with the response status
      final responseLog = logs.firstWhere(
        (log) => log.message.contains('Response'),
        orElse: () => throw Exception('Response log not found'),
      );
      
      expect(responseLog.message, contains('200'));
    });

    test('logs request body for POST requests', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/test'),
        body: jsonEncode({'test': 'data'}),
        headers: {'Content-Type': 'application/json'},
      );

      final handler = middleware(innerHandler);
      await handler(request);

      // Wait for logs to be processed
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Check that the request body was logged
      final logs = await logRecords.stream.take(2).toList();
      
      // Find the log entry with the request body
      final bodyLog = logs.firstWhere(
        (log) => log.message.contains('Request body'),
        orElse: () => throw Exception('Request body log not found'),
      );
      
      expect(bodyLog.message, contains('test'));
      expect(bodyLog.message, contains('data'));
    });

    test('logs errors', () async {
      final request = Request('GET', Uri.parse('http://localhost/api/error'));

      final handler = middleware(errorHandler);
      
      // The handler will throw an exception
      await expectLater(
        () => handler(request),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Test error'),
        )),
      );

      // Wait for logs to be processed
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Check that the error was logged
      final logs = await logRecords.stream.take(2).toList();
      
      // Find the log entry with the error
      final errorLog = logs.firstWhere(
        (log) => log.level == Level.SEVERE,
        orElse: () => throw Exception('Error log not found'),
      );
      
      expect(errorLog.message, contains('Error'));
      expect(errorLog.error.toString(), contains('Test error'));
    });

    test('logs request duration', () async {
      final request = Request('GET', Uri.parse('http://localhost/api/test'));

      final handler = middleware((request) async {
        // Simulate some processing time
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Response.ok('Success');
      });
      
      await handler(request);

      // Wait for logs to be processed
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Check that the duration was logged
      final logs = await logRecords.stream.take(2).toList();
      
      // Find the log entry with the duration
      final durationLog = logs.firstWhere(
        (log) => log.message.contains('completed in'),
        orElse: () => throw Exception('Duration log not found'),
      );
      
      expect(durationLog.message, contains('ms'));
      
      // Extract the duration value
      final durationRegex = RegExp(r'completed in (\d+)ms');
      final match = durationRegex.firstMatch(durationLog.message);
      
      if (match != null) {
        final duration = int.parse(match.group(1)!);
        expect(duration, greaterThanOrEqualTo(50));
      } else {
        fail('Duration not found in log message');
      }
    });
  });
}
