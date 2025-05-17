import 'package:multi_llm_api/core/config/env_config.dart';
import 'package:multi_llm_api/core/error/app_exception.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';

/// Configuration for database connections.
///
/// Provides methods to create and manage PostgreSQL connections.
class DbConfig {
  static final Logger _log = Logger('DbConfig');

  /// The maximum number of concurrent connections in the pool.
  static const int maxConnections = 5;

  /// Connection pool for database operations.
  static final List<Connection> _connectionPool = [];

  /// Creates a new database connection using environment variables.
  ///
  /// Returns a [Connection] configured with the database settings
  /// from environment variables.
  static Future<Connection> createConnection() async {
    final endpoint = Endpoint(
      host: EnvConfig.dbHost,
      port: EnvConfig.dbPort,
      database: EnvConfig.dbName,
      username: EnvConfig.dbUsername,
      password: EnvConfig.dbPassword,
    );

    try {
      final connection = await Connection.open(
        endpoint,
        settings: ConnectionSettings(
          sslMode: EnvConfig.dbUseSSL ? SslMode.require : SslMode.disable,
        ),
      );
      _log.info(
          'Database connection established to ${endpoint.host}:${endpoint.port}/${endpoint.database}');
      return connection;
    } catch (e, stackTrace) {
      _log.severe('Failed to connect to database', e, stackTrace);
      rethrow;
    }
  }

  /// Gets a connection from the pool or creates a new one if needed.
  ///
  /// Returns a [Connection] that is open and ready to use.
  static Future<Connection> getConnection() async {
    // Check if there's an available connection in the pool
    for (final conn in _connectionPool) {
      if (conn.isOpen) {
        return conn;
      }
    }

    // If pool is not full, create a new connection
    if (_connectionPool.length < maxConnections) {
      final conn = await createConnection();
      _connectionPool.add(conn);
      return conn;
    }

    // If all connections are busy, wait for one to become available
    _log.warning(
        'All database connections are busy. Waiting for an available connection.');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return getConnection();
  }

  /// Executes a function within a database transaction.
  ///
  /// This method will:
  /// 1. Begin a transaction
  /// 2. Execute the provided function with the connection
  /// 3. Commit the transaction if the function completes successfully
  /// 4. Rollback the transaction if an error occurs
  ///
  /// Example usage:
  /// ```dart
  /// final result = await DbConfig.withTransaction((conn) async {
  ///   // Perform multiple database operations
  ///   await conn.execute('INSERT INTO users (name) VALUES (@name)', {'name': 'John'});
  ///   await conn.execute('INSERT INTO profiles (user_id) VALUES (@id)', {'id': 1});
  ///   return 'Success';
  /// });
  /// ```
  ///
  /// Returns the result of the [operation] function.
  /// Throws any exceptions that occur during the transaction.
  static Future<T> withTransaction<T>(
      Future<T> Function(Connection conn) operation) async {
    final conn = await getConnection();
    
    try {
      // Begin transaction
      await conn.execute('BEGIN');
      _log.fine('Transaction started');
      
      // Execute the operation
      final result = await operation(conn);
      
      // Commit transaction
      await conn.execute('COMMIT');
      _log.fine('Transaction committed');
      
      return result;
    } catch (e, stackTrace) {
      // Rollback transaction on error
      try {
        await conn.execute('ROLLBACK');
        _log.fine('Transaction rolled back due to error');
      } catch (rollbackError) {
        _log.severe('Failed to rollback transaction', rollbackError);
      }
      
      _log.severe('Transaction failed', e, stackTrace);
      
      if (e is AppException) {
        rethrow;
      }
      
      throw InternalServerException('Database transaction failed: ${e.toString()}');
    }
  }

  /// Closes all connections in the pool.
  static Future<void> closeAllConnections() async {
    _log.info('Closing all database connections');
    for (final conn in _connectionPool) {
      await conn.close();
    }
    _connectionPool.clear();
  }

  /// Initializes the database with required tables and initial data.
  ///
  /// This method should be called during application startup.
  static Future<void> initializeDatabase() async {
    _log.info('Initializing database');
    final conn = await getConnection();

    try {
      // Create items table if it doesn't exist
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS items (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          description TEXT NOT NULL,
          created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create users table if it doesn't exist (for JWT auth)
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          username VARCHAR(50) NOT NULL UNIQUE,
          password_hash VARCHAR(255) NOT NULL,
          salt VARCHAR(50) NOT NULL,
          role VARCHAR(20) NOT NULL DEFAULT 'user',
          created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create refresh_tokens table if it doesn't exist
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS refresh_tokens (
          id SERIAL PRIMARY KEY,
          user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          token VARCHAR(255) NOT NULL UNIQUE,
          expires_at TIMESTAMP NOT NULL,
          is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
          created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT fk_user
            FOREIGN KEY(user_id)
            REFERENCES users(id)
            ON DELETE CASCADE
        )
      ''');

      // Create index on token for faster lookups
      await conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token
        ON refresh_tokens(token)
      ''');

      // Create index on user_id for faster lookups
      await conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id
        ON refresh_tokens(user_id)
      ''');

      // Check if we need to create a default user
      final userCountResult =
          await conn.execute('SELECT COUNT(*) as count FROM users');
      final count = userCountResult.first[0] as int;

      if (count == 0) {
        // Create default user (in a real app, use a secure password hash)
        // This is just for demonstration purposes
        await conn.execute('''
          INSERT INTO users (username, password_hash, salt, role)
          VALUES ('admin', 'hashed_password_would_go_here', 'salt_would_go_here', 'admin')
        ''');

        _log.info('Created default admin user');
      }

      _log.info('Database initialization completed successfully');
    } catch (e, stackTrace) {
      _log.severe('Failed to initialize database', e, stackTrace);
      rethrow;
    }
  }
}
