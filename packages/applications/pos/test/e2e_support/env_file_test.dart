// Dart imports:
import 'dart:io';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/env_file.dart';

const _keys = ['E2E_ADMIN_USERNAME', 'E2E_ADMIN_PASSWORD'];

void main() {
  group('parseEnvFile', () {
    test('reads KEY=value lines', () {
      // Act
      final values = parseEnvFile('A=1\nB=two words\n');

      // Assert
      expect(values, {'A': '1', 'B': 'two words'});
    });

    test('skips blank lines and # comments', () {
      // Act
      final values = parseEnvFile('# a comment\n\n  # indented\nA=1\n');

      // Assert
      expect(values, {'A': '1'});
    });

    test('splits at the first = so a value may contain =', () {
      // Act
      final values = parseEnvFile('A=x=y==\n');

      // Assert
      expect(values, {'A': 'x=y=='});
    });

    test('keeps quotes and # inside a value as they are', () {
      // Act
      final values = parseEnvFile('A="q"#not-a-comment\n');

      // Assert
      expect(values, {'A': '"q"#not-a-comment'});
    });

    test('trims spaces around keys and values and handles CRLF', () {
      // Act
      final values = parseEnvFile(' A = 1 \r\nB=2\r\n');

      // Assert
      expect(values, {'A': '1', 'B': '2'});
    });

    test('rejects a line without = naming its line number, not its text', () {
      // Act
      Object? error;
      try {
        parseEnvFile('A=1\nsecret-without-key\n');
      } on FormatException catch (e) {
        error = e;
      }

      // Assert
      expect(error, isA<FormatException>());
      expect('$error', contains('line 2'));
      expect('$error', isNot(contains('secret-without-key')));
    });
  });

  group('readEnvFile', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('env_file_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('returns the required keys from the file', () {
      // Arrange
      final file = File('${dir.path}/.env')
        ..writeAsStringSync(
            'E2E_ADMIN_USERNAME=a\nE2E_ADMIN_PASSWORD=p\nX=y\n');

      // Act
      final values = readEnvFile(file.path, _keys);

      // Assert
      expect(values, {'E2E_ADMIN_USERNAME': 'a', 'E2E_ADMIN_PASSWORD': 'p'});
    });

    test('throws naming the path when the file is missing', () {
      // Arrange
      final path = '${dir.path}/missing.env';

      // Act / Assert
      expect(
        () => readEnvFile(path, _keys),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains(path))),
      );
    });

    test('throws naming a missing or empty key, never a value', () {
      // Arrange
      final file = File('${dir.path}/.env')
        ..writeAsStringSync(
            'E2E_ADMIN_USERNAME=someone\nE2E_ADMIN_PASSWORD=\n');

      // Act / Assert
      expect(
        () => readEnvFile(file.path, _keys),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('E2E_ADMIN_PASSWORD'))
            .having((e) => e.message, 'message', isNot(contains('someone')))),
      );
    });
  });
}
