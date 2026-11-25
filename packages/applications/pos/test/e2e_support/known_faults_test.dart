// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/known_faults.dart';

FlutterErrorDetails _overflowIn(String widget) => FlutterErrorDetails(
      exception: FlutterError('A RenderFlex overflowed by 30 pixels on the '
          'bottom.'),
      library: 'rendering library',
      informationCollector: () => [
        DiagnosticsNode.message('The relevant error-causing widget was:'),
        DiagnosticsNode.message('  $widget'),
      ],
    );

final _pickerOverflow = _overflowIn('DropdownButtonFormField<Supplier>');

void main() {
  group('isSupplierPickerOverflow', () {
    test('matches an overflow raised by the supplier picker', () {
      // Act / Assert
      expect(isSupplierPickerOverflow(_pickerOverflow), isTrue);
    });

    test('does not match an overflow anywhere else', () {
      // Act / Assert
      expect(
          isSupplierPickerOverflow(
              _overflowIn('DropdownButtonFormField<ItemType>')),
          isFalse);
    });

    test('does not match another error from the supplier picker', () {
      // Arrange
      final other = FlutterErrorDetails(
        exception: FlutterError('There should be exactly one item'),
        informationCollector: () =>
            [DiagnosticsNode.message('DropdownButtonFormField<Supplier>')],
      );

      // Act / Assert
      expect(isSupplierPickerOverflow(other), isFalse);
    });
  });

  group('onReceiptPage', () {
    late FlutterExceptionHandler? testHandler;
    late List<FlutterErrorDetails> reached;

    setUp(() {
      testHandler = FlutterError.onError;
      reached = [];
      FlutterError.onError = reached.add;
    });

    tearDown(() => FlutterError.onError = testHandler);

    test('swallows the picker overflow and counts it', () async {
      // Arrange
      final before = supplierPickerOverflowsSwallowed;

      // Act
      await onReceiptPage(() async {
        FlutterError.reportError(_pickerOverflow);
      });

      // Assert
      expect(reached, isEmpty);
      expect(supplierPickerOverflowsSwallowed, before + 1);
    });

    test('passes any other error to the handler in place, uncounted', () async {
      // Arrange
      final before = supplierPickerOverflowsSwallowed;
      final other = _overflowIn('DropdownButtonFormField<ItemType>');

      // Act
      await onReceiptPage(() async => FlutterError.reportError(other));

      // Assert
      expect(reached, [other]);
      expect(supplierPickerOverflowsSwallowed, before);
    });

    test('restores the handler in place when the body throws', () async {
      // Arrange
      final inPlace = FlutterError.onError;

      // Act
      await expectLater(
          onReceiptPage(() async => throw StateError('step failed')),
          throwsStateError);

      // Assert
      expect(FlutterError.onError, same(inPlace));
      FlutterError.reportError(_pickerOverflow);
      expect(reached, [_pickerOverflow],
          reason: 'outside the wrapper nothing is tolerated');
    });

    test('takes the handler in place when it starts, not when defined',
        () async {
      // Arrange: a handler installed later, as the test binding does
      final installedLater = <FlutterErrorDetails>[];
      FlutterError.onError = installedLater.add;
      final other = _overflowIn('Row');

      // Act
      await onReceiptPage(() async => FlutterError.reportError(other));

      // Assert
      expect(installedLater, [other]);
      expect(reached, isEmpty);
    });
  });
}
