// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/stock_plan.dart';

void main() {
  group('runLot', () {
    test('is L and the run id', () {
      // Act
      final lot = runLot('20261124153012-4242');

      // Assert
      expect(lot, 'L20261124153012-4242');
    });
  });

  group('expiryOneYearAfter', () {
    test('is the same day next year as YYYY-MM-DD, zero-padded', () {
      // Act
      final expiry = expiryOneYearAfter(DateTime(2026, 3, 5, 23, 59));

      // Assert
      expect(expiry, '2027-03-05');
    });

    test('moves 29 February to 1 March', () {
      // Act
      final expiry = expiryOneYearAfter(DateTime(2028, 2, 29));

      // Assert
      expect(expiry, '2029-03-01');
    });
  });

  group('shortDate', () {
    test('is d/M/yy as the stock tab shows a date', () {
      // Act
      final shown = shortDate('2027-03-05');

      // Assert
      expect(shown, '5/3/27');
    });
  });

  group('onHandIn', () {
    test('reads the quantity from the sorted list subtitle', () {
      // Act
      final onHand = onHandIn('คงเหลือ 12 ชิ้น');

      // Assert
      expect(onHand, 12);
    });

    test('reads a negative quantity', () {
      // Act
      final onHand = onHandIn('คงเหลือ -3 ชิ้น');

      // Assert
      expect(onHand, -3);
    });

    test('reads the quantity after the price in a product row', () {
      // Act
      final onHand = onHandIn('฿10.00 · คงเหลือ 12 ชิ้น');

      // Assert
      expect(onHand, 12);
    });

    test('reads the quantity when a stock cue follows it', () {
      // Act
      final onHand = onHandIn('฿10.00 · คงเหลือ 0 ชิ้น · หมด');

      // Assert
      expect(onHand, 0);
    });

    test('is null for the unsorted subtitle, which is only the unit', () {
      // Act
      final onHand = onHandIn('ชิ้น');

      // Assert
      expect(onHand, isNull);
    });
  });

  group('StepChain', () {
    test('runs a step while nothing has failed', () async {
      // Arrange
      final chain = StepChain();
      var ran = false;

      // Act
      await chain.run('first', () async => ran = true);

      // Assert
      expect(ran, isTrue);
    });

    test('rethrows a failing step', () async {
      // Arrange
      final chain = StepChain();

      // Act / Assert
      await expectLater(
          chain.run('first', () async => throw StateError('broken')),
          throwsStateError);
    });

    test('fails every later step at once, naming the one that failed',
        () async {
      // Arrange
      final chain = StepChain();
      await chain
          .run('first', () async => throw StateError('broken'))
          .catchError((_) {});
      var ran = false;

      // Act / Assert
      await expectLater(
        chain.run('second', () async => ran = true),
        throwsA(isA<TestFailure>()
            .having((f) => f.message, 'message', contains('"first" failed'))),
      );
      expect(ran, isFalse);
    });
  });
}
