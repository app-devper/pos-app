// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/cleanup.dart';

void main() {
  group('UndoStack.run', () {
    test('undoes the latest addition first', () async {
      // Arrange
      final undone = <String>[];
      final stack = UndoStack<String>()
        ..add('product', (_) async => undone.add('product'))
        ..add('stock', (_) async => undone.add('stock'))
        ..add('sale', (_) async => undone.add('sale'));

      // Act
      await stack.run('context');

      // Assert
      expect(undone, ['sale', 'stock', 'product']);
    });

    test('keeps going after an undo fails and returns what was left', () async {
      // Arrange
      final undone = <String>[];
      final stack = UndoStack<String>()
        ..add('product', (_) async => undone.add('product'))
        ..add('customer', (_) async => throw StateError('server said no'))
        ..add('stock', (_) async => throw Exception('offline'))
        ..add('sale', (_) async => undone.add('sale'));

      // Act
      final leftovers = await stack.run('context');

      // Assert
      expect(undone, ['sale', 'product']);
      expect(leftovers, ['stock', 'customer']);
    });

    test('hands every undo the context it runs with', () async {
      // Arrange
      final seen = <String>[];
      final stack = UndoStack<String>()
        ..add('product', (context) async => seen.add(context));

      // Act
      await stack.run('the tester');

      // Assert
      expect(seen, ['the tester']);
    });

    test('forgets what it ran, so a second run undoes nothing', () async {
      // Arrange
      var calls = 0;
      final stack = UndoStack<String>()..add('product', (_) async => calls++);
      await stack.run('context');

      // Act
      final leftovers = await stack.run('context');

      // Assert
      expect(calls, 1);
      expect(leftovers, isEmpty);
    });
  });

  group('leftoversLine', () {
    test('says none when everything was undone', () {
      // Act / Assert
      expect(leftoversLine([]), 'E2E leftovers: none');
    });

    test('lists every label that could not be undone', () {
      // Act / Assert
      expect(
        leftoversLine(['E2E-1 product', 'E2E-1 customer']),
        'E2E leftovers: E2E-1 product, E2E-1 customer',
      );
    });
  });
}
