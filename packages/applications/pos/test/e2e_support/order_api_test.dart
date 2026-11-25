// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/api/order_api.dart';

bool _covers(({DateTime start, DateTime end}) window, DateTime at) =>
    !at.isBefore(window.start) && at.isBefore(window.end);

void main() {
  group('billWindow', () {
    test('a bill paid before midnight is still covered just after it', () {
      // Arrange
      final firstLook = DateTime(2026, 11, 25, 23, 59, 50);
      final paid = DateTime(2026, 11, 25, 23, 59, 55);
      final now = DateTime(2026, 11, 26, 0, 0, 10);

      // Act
      final window = billWindow(firstLook, now);

      // Assert
      expect(_covers(window, paid), isTrue);
      expect(_covers(window, DateTime(2026, 11, 26, 0, 0, 5)), isTrue,
          reason: 'and one paid after midnight');
    });

    test('starts at the local midnight of the first look', () {
      // Act
      final window = billWindow(
          DateTime(2026, 11, 25, 9, 30), DateTime(2026, 11, 25, 9, 31));

      // Assert
      expect(window.start, DateTime(2026, 11, 25));
      expect(_covers(window, DateTime(2026, 11, 24, 23, 59, 59)), isFalse);
    });

    test('ends a day after now, past a server clock running ahead', () {
      // Act
      final window = billWindow(
          DateTime(2026, 11, 25, 9, 30), DateTime(2026, 11, 25, 9, 31));

      // Assert
      expect(window.end, DateTime(2026, 11, 26, 9, 31));
    });
  });
}
