import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation state is published through ViewState, never a bare '
      'ValueNotifier', () {
    final sources = Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    final bare = RegExp(r'\bValueNotifier\b');

    final offenders = sources
        .where((file) => bare.hasMatch(file.readAsStringSync()))
        .map((file) => file.path)
        .toList()
      ..sort();

    expect(sources, isNotEmpty,
        reason: 'nothing was scanned, so this test would pass on anything');
    expect(offenders, isEmpty,
        reason: 'a bare ValueNotifier asserts in debug when a request answers '
            'after the screen is gone; ViewState ignores it '
            '(common/core/state/view_state.dart)');
  });
}
