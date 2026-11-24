// Dart imports:
import 'dart:async';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/cleanup.dart';

void main() {
  group('UndoStack.run', () {
    test('undoes the latest addition first', () async {
      // Arrange
      final undone = <String>[];
      final stack = UndoStack()
        ..add('product', () async => undone.add('product'))
        ..add('stock', () async => undone.add('stock'))
        ..add('sale', () async => undone.add('sale'));

      // Act
      await stack.run();

      // Assert
      expect(undone, ['sale', 'stock', 'product']);
    });

    test('keeps going after an undo fails and returns what was left', () async {
      // Arrange
      final undone = <String>[];
      final stack = UndoStack()
        ..add('product', () async => undone.add('product'))
        ..add('customer', () async => throw StateError('server said no'))
        ..add('stock', () async => throw Exception('offline'))
        ..add('sale', () async => undone.add('sale'));

      // Act
      final leftovers = await stack.run();

      // Assert
      expect(undone, ['sale', 'product']);
      expect(leftovers, ['stock', 'customer']);
    });

    test('gives up on an undo that hangs and lists it as left over', () async {
      // Arrange
      final undone = <String>[];
      final stack = UndoStack(timeout: const Duration(milliseconds: 50))
        ..add('product', () async => undone.add('product'))
        ..add('stuck', () => Completer<void>().future);

      // Act
      final leftovers = await stack.run();

      // Assert
      expect(leftovers, ['stuck']);
      expect(undone, ['product']);
    });

    test('forgets what it ran, so a second run undoes nothing', () async {
      // Arrange
      var calls = 0;
      final stack = UndoStack()..add('product', () async => calls++);
      await stack.run();

      // Act
      final leftovers = await stack.run();

      // Assert
      expect(calls, 1);
      expect(leftovers, isEmpty);
      expect(stack.pending, isEmpty);
    });
  });

  group('CleanupLedger', () {
    test('registers one tear-down per test, however many undos are added', () {
      // Arrange
      final tearDowns = <Future<void> Function()>[];
      final ledger = CleanupLedger(registerTearDown: tearDowns.add);

      // Act
      ledger
        ..add('product', () async {})
        ..add('stock', () async {});

      // Assert
      expect(tearDowns, hasLength(1));
    });

    test('its tear-down runs the undos and records what failed', () async {
      // Arrange
      final tearDowns = <Future<void> Function()>[];
      final ledger = CleanupLedger(registerTearDown: tearDowns.add)
        ..add('product', () async {})
        ..add('customer', () async => throw Exception('offline'));

      // Act
      await tearDowns.single();

      // Assert
      expect(ledger.report(), 'E2E leftovers: customer');
    });

    test('registers again for the next test once its tear-down has run',
        () async {
      // Arrange
      final tearDowns = <Future<void> Function()>[];
      final ledger = CleanupLedger(registerTearDown: tearDowns.add)
        ..add('product', () async {});
      await tearDowns.single();

      // Act
      ledger.add('stock', () async {});

      // Assert
      expect(tearDowns, hasLength(2));
    });

    test('lists undos still pending at report time as left over', () {
      // Arrange: a tear-down that never ran
      final ledger = CleanupLedger(registerTearDown: (_) {})
        ..add('product', () async {});

      // Act
      final report = ledger.report();

      // Assert
      expect(report, 'E2E leftovers: product');
    });

    test('reports none when everything was undone', () async {
      // Arrange
      final tearDowns = <Future<void> Function()>[];
      final ledger = CleanupLedger(registerTearDown: tearDowns.add)
        ..add('product', () async {});
      await tearDowns.single();

      // Act / Assert
      expect(ledger.report(), 'E2E leftovers: none');
    });
  });

  group('Cleanup, with the real test framework', () {
    final undone = <String>[];

    test('an undo added and never run explicitly ...', () {
      // Arrange / Act
      Cleanup.add('E2E-test product', () async => undone.add('product'));
    });

    test('... has run by the time the next test starts', () {
      // Assert
      expect(undone, ['product']);
    });
  });
}
