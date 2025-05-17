import 'package:multi_llm_api/core/utils/input_sanitizer.dart';
import 'package:test/test.dart';

void main() {
  group('InputSanitizer', () {
    group('sanitizeSql', () {
      test('returns empty string for null input', () {
        expect(InputSanitizer.sanitizeSql(null), equals(''));
      });

      test('returns empty string for empty input', () {
        expect(InputSanitizer.sanitizeSql(''), equals(''));
      });

      test('escapes single quotes', () {
        expect(InputSanitizer.sanitizeSql("O'Reilly"), equals("O''Reilly"));
      });

      test('removes SQL comment markers', () {
        expect(InputSanitizer.sanitizeSql('value--comment'), equals('valuecomment'));
        expect(InputSanitizer.sanitizeSql('value;--comment'), equals('valuecomment'));
        expect(InputSanitizer.sanitizeSql('value;#comment'), equals('valuecomment'));
      });

      test('removes SQL injection keywords', () {
        expect(InputSanitizer.sanitizeSql('DROP TABLE users'), equals(' TABLE users'));
        expect(InputSanitizer.sanitizeSql('DELETE FROM users'), equals(' FROM users'));
        expect(InputSanitizer.sanitizeSql('UPDATE users SET'), equals(' users SET'));
        expect(InputSanitizer.sanitizeSql('INSERT INTO users'), equals(' INTO users'));
        expect(InputSanitizer.sanitizeSql('TRUNCATE TABLE users'), equals(' TABLE users'));
        expect(InputSanitizer.sanitizeSql('ALTER TABLE users'), equals(' TABLE users'));
        expect(InputSanitizer.sanitizeSql('EXEC sp_execute_sql'), equals(' sp_execute_sql'));
        expect(InputSanitizer.sanitizeSql('EXECUTE sp_execute_sql'), equals(' sp_execute_sql'));
      });
    });

    group('sanitizeHtml', () {
      test('returns empty string for null input', () {
        expect(InputSanitizer.sanitizeHtml(null), equals(''));
      });

      test('returns empty string for empty input', () {
        expect(InputSanitizer.sanitizeHtml(''), equals(''));
      });

      test('escapes HTML special characters', () {
        expect(
          InputSanitizer.sanitizeHtml('<script>alert("XSS")</script>'),
          equals('&lt;script&gt;alert(&quot;XSS&quot;)&lt;&#x2F;script&gt;'),
        );
        expect(
          InputSanitizer.sanitizeHtml('<a href="javascript:alert(\'XSS\')">Click me</a>'),
          equals('&lt;a href=&quot;javascript:alert(&#x27;XSS&#x27;)&quot;&gt;Click me&lt;&#x2F;a&gt;'),
        );
      });

      test('preserves normal text', () {
        expect(
          InputSanitizer.sanitizeHtml('Hello, world!'),
          equals('Hello, world!'),
        );
      });
    });

    group('sanitizeFilePath', () {
      test('returns empty string for null input', () {
        expect(InputSanitizer.sanitizeFilePath(null), equals(''));
      });

      test('returns empty string for empty input', () {
        expect(InputSanitizer.sanitizeFilePath(''), equals(''));
      });

      test('removes path traversal sequences', () {
        expect(InputSanitizer.sanitizeFilePath('../etc/passwd'), equals('etcpasswd'));
        expect(InputSanitizer.sanitizeFilePath('../../etc/passwd'), equals('etcpasswd'));
        expect(InputSanitizer.sanitizeFilePath('/etc/passwd'), equals('etcpasswd'));
        expect(InputSanitizer.sanitizeFilePath('C:\\Windows\\System32'), equals('CWindowsSystem32'));
      });

      test('preserves normal filename', () {
        expect(InputSanitizer.sanitizeFilePath('myfile.txt'), equals('myfile.txt'));
      });
    });

    group('sanitizeShellCommand', () {
      test('returns empty string for null input', () {
        expect(InputSanitizer.sanitizeShellCommand(null), equals(''));
      });

      test('returns empty string for empty input', () {
        expect(InputSanitizer.sanitizeShellCommand(''), equals(''));
      });

      test('escapes shell special characters', () {
        expect(InputSanitizer.sanitizeShellCommand('echo "Hello"'), equals('echo \\"Hello\\"'));
        expect(InputSanitizer.sanitizeShellCommand('ls -la | grep file'), equals('ls -la \\| grep file'));
        expect(InputSanitizer.sanitizeShellCommand('cat file > output.txt'), equals('cat file \\> output.txt'));
        expect(InputSanitizer.sanitizeShellCommand('echo \$HOME'), equals('echo \\\$HOME'));
        expect(InputSanitizer.sanitizeShellCommand('echo `whoami`'), equals('echo \\`whoami\\`'));
        expect(InputSanitizer.sanitizeShellCommand('echo \'text\''), equals('echo \\\'text\\\''));
        expect(InputSanitizer.sanitizeShellCommand('cmd1 && cmd2'), equals('cmd1 \\&\\& cmd2'));
        expect(InputSanitizer.sanitizeShellCommand('cmd1 ; cmd2'), equals('cmd1 \\; cmd2'));
        expect(InputSanitizer.sanitizeShellCommand('echo (date)'), equals('echo \\(date\\)'));
      });
    });

    group('sanitizeString', () {
      test('returns empty string for null input', () {
        expect(InputSanitizer.sanitizeString(null), equals(''));
      });

      test('returns empty string for empty input', () {
        expect(InputSanitizer.sanitizeString(''), equals(''));
      });

      test('trims whitespace', () {
        expect(InputSanitizer.sanitizeString('  Hello  '), equals('Hello'));
      });

      test('removes control characters', () {
        expect(InputSanitizer.sanitizeString('Hello\x00World'), equals('HelloWorld'));
        expect(InputSanitizer.sanitizeString('Hello\nWorld'), equals('HelloWorld'));
        expect(InputSanitizer.sanitizeString('Hello\tWorld'), equals('HelloWorld'));
      });
    });

    group('sanitizeEmail', () {
      test('returns empty string for null input', () {
        expect(InputSanitizer.sanitizeEmail(null), equals(''));
      });

      test('returns empty string for empty input', () {
        expect(InputSanitizer.sanitizeEmail(''), equals(''));
      });

      test('returns empty string for invalid email', () {
        expect(InputSanitizer.sanitizeEmail('not-an-email'), equals(''));
        expect(InputSanitizer.sanitizeEmail('user@'), equals(''));
        expect(InputSanitizer.sanitizeEmail('@example.com'), equals(''));
        expect(InputSanitizer.sanitizeEmail('user@example'), equals(''));
      });

      test('returns lowercase trimmed email for valid email', () {
        expect(InputSanitizer.sanitizeEmail('User@Example.com '), equals('user@example.com'));
        expect(InputSanitizer.sanitizeEmail(' john.doe@example.co.uk'), equals('john.doe@example.co.uk'));
      });
    });

    group('sanitizePhoneNumber', () {
      test('returns empty string for null input', () {
        expect(InputSanitizer.sanitizePhoneNumber(null), equals(''));
      });

      test('returns empty string for empty input', () {
        expect(InputSanitizer.sanitizePhoneNumber(''), equals(''));
      });

      test('removes non-digit characters', () {
        expect(InputSanitizer.sanitizePhoneNumber('+1 (555) 123-4567'), equals('15551234567'));
        expect(InputSanitizer.sanitizePhoneNumber('555.123.4567'), equals('5551234567'));
        expect(InputSanitizer.sanitizePhoneNumber('555-123-4567'), equals('5551234567'));
      });

      test('preserves only digits', () {
        expect(InputSanitizer.sanitizePhoneNumber('abc123def456'), equals('123456'));
      });
    });
  });
}
