import 'dart:io';

import 'package:multi_llm_api/core/server/server_setup.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Starts a test server for integration tests.
///
/// Returns a [HttpServer] instance that can be used to make requests to the server.
/// The server will listen on a random port.
Future<HttpServer> startTestServer() async {
  // Setup server handler (routes, middleware)
  final handler = setupServerHandler();

  // Start the server on a random port
  final server = await io.serve(handler, 'localhost', 0);
  
  print('Test server started on port ${server.port}');
  
  return server;
}
