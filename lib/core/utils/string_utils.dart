/// Utility class for string manipulation.
class StringUtils {
  /// Private constructor to prevent instantiation.
  StringUtils._();

  /// Truncates a string to the specified length and adds an ellipsis if truncated.
  ///
  /// [text] is the string to truncate.
  /// [maxLength] is the maximum length of the string.
  /// [ellipsis] is the string to append if the text is truncated.
  ///
  /// Returns the truncated string.
  static String truncate(
    String text, {
    int maxLength = 50,
    String ellipsis = '...',
  }) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}$ellipsis';
  }

  /// Capitalizes the first letter of a string.
  ///
  /// [text] is the string to capitalize.
  ///
  /// Returns the capitalized string.
  static String capitalize(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Converts a string to camel case.
  ///
  /// [text] is the string to convert.
  ///
  /// Returns the camel case string.
  static String toCamelCase(String text) {
    if (text.isEmpty) {
      return text;
    }

    // Split the string by non-alphanumeric characters
    final parts = text.split(RegExp(r'[^a-zA-Z0-9]'));
    
    // Capitalize each part except the first one
    final result = StringBuffer(parts[0].toLowerCase());
    for (var i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        result.write(capitalize(parts[i].toLowerCase()));
      }
    }
    
    return result.toString();
  }

  /// Converts a string to snake case.
  ///
  /// [text] is the string to convert.
  ///
  /// Returns the snake case string.
  static String toSnakeCase(String text) {
    if (text.isEmpty) {
      return text;
    }

    // Replace non-alphanumeric characters with underscores
    var result = text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    
    // Replace uppercase letters with underscore + lowercase letter
    result = result.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    );
    
    // Remove consecutive underscores and leading/trailing underscores
    result = result.replaceAll(RegExp(r'_+'), '_').trim();
    if (result.startsWith('_')) {
      result = result.substring(1);
    }
    if (result.endsWith('_')) {
      result = result.substring(0, result.length - 1);
    }
    
    return result.toLowerCase();
  }

  /// Converts a string to kebab case.
  ///
  /// [text] is the string to convert.
  ///
  /// Returns the kebab case string.
  static String toKebabCase(String text) {
    return toSnakeCase(text).replaceAll('_', '-');
  }

  /// Checks if a string is null, empty, or contains only whitespace.
  ///
  /// [text] is the string to check.
  ///
  /// Returns true if the string is null, empty, or contains only whitespace.
  static bool isNullOrEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// Checks if a string is a valid email address.
  ///
  /// [email] is the string to check.
  ///
  /// Returns true if the string is a valid email address.
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Checks if a string is a valid URL.
  ///
  /// [url] is the string to check.
  ///
  /// Returns true if the string is a valid URL.
  static bool isValidUrl(String url) {
    final urlRegex = RegExp(
      r'^(http|https)://[a-zA-Z0-9-_.]+\.[a-zA-Z]{2,}(:[0-9]+)?(/.*)?$',
    );
    return urlRegex.hasMatch(url);
  }

  /// Removes all HTML tags from a string.
  ///
  /// [html] is the string containing HTML.
  ///
  /// Returns the string without HTML tags.
  static String stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Masks a string by replacing characters with a mask character.
  ///
  /// [text] is the string to mask.
  /// [visibleCharsStart] is the number of characters to show at the beginning.
  /// [visibleCharsEnd] is the number of characters to show at the end.
  /// [maskChar] is the character to use for masking.
  ///
  /// Returns the masked string.
  static String mask(
    String text, {
    int visibleCharsStart = 4,
    int visibleCharsEnd = 4,
    String maskChar = '*',
  }) {
    if (text.length <= visibleCharsStart + visibleCharsEnd) {
      return text;
    }
    
    final start = text.substring(0, visibleCharsStart);
    final end = text.substring(text.length - visibleCharsEnd);
    final masked = maskChar * (text.length - visibleCharsStart - visibleCharsEnd);
    
    return '$start$masked$end';
  }
}
