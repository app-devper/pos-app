import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a view model publishes through ViewState, never a bare ValueNotifier',
      () {
    final offenders = Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => file.uri.pathSegments.last.contains('view_model'))
        .where((file) => file.readAsStringSync().contains('ValueNotifier<'))
        .map((file) => file.path)
        .toList()
      ..sort();

    expect(offenders, isEmpty,
        reason: 'a bare ValueNotifier asserts when a request answers after '
            'the screen is gone; ViewState ignores it '
            '(common/core/state/view_state.dart)');
  });
}
