/// Utility class for sanitizing user inputs to prevent various injection attacks.
///
/// This class provides methods to sanitize strings against common security threats
/// such as SQL injection, HTML/JavaScript injection, and more.
class InputSanitizer {
  // Private constructor to prevent instantiation
  InputSanitizer._();

  /// Sanitizes a string against SQL injection attacks.
  ///
  /// This method escapes single quotes and other characters that could be used
  /// for SQL injection. Note that this is a basic sanitization and should be used
  /// in addition to parameterized queries, not as a replacement.
  ///
  /// [input] is the string to sanitize.
  /// Returns the sanitized string.
  static String sanitizeSql(String? input) {
    if (input == null || input.isEmpty) {
      return '';
    }

    // Escape single quotes by doubling them
    var sanitized = input.replaceAll("'", "''");
    
    // Remove SQL comment markers
    sanitized = sanitized.replaceAll('--', '');
    sanitized = sanitized.replaceAll(';--', '');
    sanitized = sanitized.replaceAll(';', '');
    sanitized = sanitized.replaceAll('#', '');
    
    // Remove common SQL injection patterns
    sanitized = sanitized.replaceAll('DROP ', ' ');
    sanitized = sanitized.replaceAll('DELETE ', ' ');
    sanitized = sanitized.replaceAll('UPDATE ', ' ');
    sanitized = sanitized.replaceAll('INSERT ', ' ');
    sanitized = sanitized.replaceAll('TRUNCATE ', ' ');
    sanitized = sanitized.replaceAll('ALTER ', ' ');
    sanitized = sanitized.replaceAll('EXEC ', ' ');
    sanitized = sanitized.replaceAll('EXECUTE ', ' ');
    
    return sanitized;
  }

  /// Sanitizes a string against HTML/JavaScript injection attacks.
  ///
  /// This method escapes HTML special characters to prevent XSS attacks.
  ///
  /// [input] is the string to sanitize.
  /// Returns the sanitized string.
  static String sanitizeHtml(String? input) {
    if (input == null || input.isEmpty) {
      return '';
    }
    
    // Replace HTML special characters with their entity equivalents
    var sanitized = input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
    
    return sanitized;
  }

  /// Sanitizes a string for use in file paths.
  ///
  /// This method removes characters that could be used for path traversal attacks.
  ///
  /// [input] is the string to sanitize.
  /// Returns the sanitized string.
  static String sanitizeFilePath(String? input) {
    if (input == null || input.isEmpty) {
      return '';
    }
    
    // Remove path traversal sequences
    var sanitized = input.replaceAll('..', '');
    sanitized = sanitized.replaceAll('/', '');
    sanitized = sanitized.replaceAll('\\', '');
    sanitized = sanitized.replaceAll(':', '');
    
    return sanitized;
  }

  /// Sanitizes a string for use in shell commands.
  ///
  /// This method escapes characters that could be used for command injection.
  ///
  /// [input] is the string to sanitize.
  /// Returns the sanitized string.
  static String sanitizeShellCommand(String? input) {
    if (input == null || input.isEmpty) {
      return '';
    }
    
    // Escape shell special characters
    var sanitized = input.replaceAll('&', '\\&');
    sanitized = sanitized.replaceAll(';', '\\;');
    sanitized = sanitized.replaceAll('|', '\\|');
    sanitized = sanitized.replaceAll('>', '\\>');
    sanitized = sanitized.replaceAll('<', '\\<');
    sanitized = sanitized.replaceAll('(', '\\(');
    sanitized = sanitized.replaceAll(')', '\\)');
    sanitized = sanitized.replaceAll('\$', '\\\$');
    sanitized = sanitized.replaceAll('`', '\\`');
    sanitized = sanitized.replaceAll('"', '\\"');
    sanitized = sanitized.replaceAll("'", "\\'");
    
    return sanitized;
  }

  /// Sanitizes a string for general use.
  ///
  /// This method applies basic sanitization for general string inputs.
  /// It trims the string and removes control characters.
  ///
  /// [input] is the string to sanitize.
  /// Returns the sanitized string.
  static String sanitizeString(String? input) {
    if (input == null || input.isEmpty) {
      return '';
    }
    
    // Trim whitespace and remove control characters
    final sanitized = input.trim().replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    return sanitized;
  }

  /// Sanitizes an email address.
  ///
  /// This method validates and sanitizes an email address.
  ///
  /// [input] is the email address to sanitize.
  /// Returns the sanitized email address, or an empty string if invalid.
  static String sanitizeEmail(String? input) {
    if (input == null || input.isEmpty) {
      return '';
    }
    
    // Basic email validation regex - allow spaces before/after for trimming
    final emailRegex = RegExp(r'^\s*[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\s*$');
    
    if (!emailRegex.hasMatch(input)) {
      return '';
    }
    
    return input.toLowerCase().trim();
  }

  /// Sanitizes a phone number.
  ///
  /// This method removes all non-digit characters from a phone number.
  ///
  /// [input] is the phone number to sanitize.
  /// Returns the sanitized phone number.
  static String sanitizePhoneNumber(String? input) {
    if (input == null || input.isEmpty) {
      return '';
    }
    
    // Remove all non-digit characters
    return input.replaceAll(RegExp(r'[^\d]'), '');
  }
}
