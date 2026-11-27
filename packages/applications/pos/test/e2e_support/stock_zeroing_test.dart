// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/stock_zeroing.dart';

void main() {
  group('zeroingDeltas', () {
    test('takes each lot down by what it holds', () {
      // Act
      final deltas = zeroingDeltas([
        (stockId: 'a', quantity: 10),
        (stockId: 'b', quantity: 3),
      ]);

      // Assert
      expect(deltas, [
        (stockId: 'a', delta: -10),
        (stockId: 'b', delta: -3),
      ]);
    });

    test('skips lots already at 0 (pos-api refuses a zero delta)', () {
      // Act
      final deltas = zeroingDeltas([
        (stockId: 'a', quantity: 0),
        (stockId: 'b', quantity: 8),
      ]);

      // Assert
      expect(deltas, [(stockId: 'b', delta: -8)]);
    });

    test('brings a negative lot up to 0', () {
      // Act
      final deltas = zeroingDeltas([(stockId: 'a', quantity: -2)]);

      // Assert
      expect(deltas, [(stockId: 'a', delta: 2)]);
    });

    test('nothing to do for no lots', () {
      expect(zeroingDeltas(const []), isEmpty);
    });
  });

  group('stockRowsToDelete', () {
    test('every row at 0 is deleted', () {
      // Act
      final plan = stockRowsToDelete([
        (stockId: 'a', quantity: 0),
        (stockId: 'b', quantity: 0),
      ]);

      // Assert
      expect(plan.delete, ['a', 'b']);
      expect(plan.keep, isEmpty);
    });

    test('a row still above 0 is not deleted and is reported', () {
      // Act
      final plan = stockRowsToDelete([
        (stockId: 'a', quantity: 0),
        (stockId: 'b', quantity: 3),
      ]);

      // Assert: pos-api refuses it (ledger/stock.go:70-72)
      expect(plan.delete, ['a']);
      expect(plan.keep, [(stockId: 'b', quantity: 3)]);
    });

    test('nothing to do for no rows', () {
      final plan = stockRowsToDelete(const []);
      expect(plan.delete, isEmpty);
      expect(plan.keep, isEmpty);
    });
  });
}
