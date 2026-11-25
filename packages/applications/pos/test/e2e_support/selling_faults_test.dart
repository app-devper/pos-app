// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/selling_faults.dart';

FlutterErrorDetails _overflowUnder(String creators) => FlutterErrorDetails(
      exception: FlutterError('A RenderFlex overflowed by 12 pixels on the '
          'bottom.'),
      library: 'rendering library',
      informationCollector: () => [
        DiagnosticsNode.message('The specific RenderFlex in question is:'),
        DiagnosticsNode.message('  creator: Column ← $creators'),
      ],
    );

final _keypadOverflow =
    _overflowUnder('Padding ← Container ← DecimalInput ← Expanded');

void main() {
  group('isQuantityKeypadOverflow', () {
    test('matches an overflow inside the quantity keypad', () {
      // Act / Assert
      expect(isQuantityKeypadOverflow(_keypadOverflow), isTrue);
    });

    test('does not match an overflow anywhere else', () {
      // Act / Assert
      expect(
          isQuantityKeypadOverflow(_overflowUnder('Padding ← PaymentScreen')),
          isFalse);
    });

    test('does not match another error inside the keypad', () {
      // Arrange
      final other = FlutterErrorDetails(
        exception: FlutterError('setState() called after dispose()'),
        informationCollector: () =>
            [DiagnosticsNode.message('creator: DecimalInput')],
      );

      // Act / Assert
      expect(isQuantityKeypadOverflow(other), isFalse);
    });
  });

  group('isPaymentDisplayOverflow', () {
    test('matches an overflow inside the payment screen only', () {
      // Act / Assert
      expect(
          isPaymentDisplayOverflow(_overflowUnder('Padding ← PaymentScreen')),
          isTrue);
      expect(isPaymentDisplayOverflow(_keypadOverflow), isFalse);
    });
  });

  group('onQuantityKeypad', () {
    late FlutterExceptionHandler? testHandler;
    late List<FlutterErrorDetails> reached;

    setUp(() {
      testHandler = FlutterError.onError;
      reached = [];
      FlutterError.onError = reached.add;
    });

    tearDown(() => FlutterError.onError = testHandler);

    test('swallows the keypad overflow and counts it', () async {
      // Arrange
      final before = quantityKeypadOverflowsSwallowed;

      // Act
      await onQuantityKeypad(
          () async => FlutterError.reportError(_keypadOverflow));

      // Assert
      expect(reached, isEmpty);
      expect(quantityKeypadOverflowsSwallowed, before + 1);
    });

    test('passes any other error on and restores the handler', () async {
      // Arrange
      final inPlace = FlutterError.onError;
      final other = _overflowUnder('Row');

      // Act
      await onQuantityKeypad(() async => FlutterError.reportError(other));

      // Assert
      expect(reached, [other]);
      expect(FlutterError.onError, same(inPlace));
    });
  });
}
