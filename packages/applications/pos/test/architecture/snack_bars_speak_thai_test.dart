import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A call that shows a bar, up to the end of its statement.
final _barCall = RegExp(r'show(?:Error)?SnackBar\([^;]*;');

/// A string literal written in the call.
final _literal = RegExp(r'"([^"]*)"' "|'([^']*)'");

/// An interpolation: `${…}` or `$name`.
final _interpolation = RegExp(r'\$\{[^}]*\}|\$\w+');

final _latinWord = RegExp(r'[A-Za-z]{2,}');

void main() {
  test(
      'no page writes the text of a snack bar in English; it comes from '
      'Languages', () {
    final sources = Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();

    final offenders = <String>[];
    for (final file in sources) {
      for (final call in _barCall.allMatches(file.readAsStringSync())) {
        for (final literal in _literal.allMatches(call.group(0)!)) {
          final text = (literal.group(1) ?? literal.group(2) ?? '')
              .replaceAll(_interpolation, '');
          if (_latinWord.hasMatch(text)) {
            offenders.add('${file.path}: "${literal.group(0)}"');
          }
        }
      }
    }

    expect(sources, isNotEmpty,
        reason: 'nothing was scanned, so this test would pass on anything');
    expect(offenders..sort(), isEmpty,
        reason: 'a bar\'s text is read by the user; Thai, from Languages '
            '(English for the en locale)');
  });
}
