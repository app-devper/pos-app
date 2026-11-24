// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/known_faults.dart';

void main() {
  group('isSupplierPickerOverflow', () {
    test('matches an overflow raised by the supplier picker', () {
      // Arrange
      const report = 'A RenderFlex overflowed by 30 pixels on the bottom.\n'
          'The relevant error-causing widget was:\n'
          '  DropdownButtonFormField<Supplier>';

      // Act / Assert
      expect(isSupplierPickerOverflow(report), isTrue);
    });

    test('does not match an overflow anywhere else', () {
      // Arrange
      const report = 'A RenderFlex overflowed by 30 pixels on the bottom.\n'
          'The relevant error-causing widget was:\n'
          '  DropdownButtonFormField<ItemType>';

      // Act / Assert
      expect(isSupplierPickerOverflow(report), isFalse);
    });

    test('does not match another error from the supplier picker', () {
      // Arrange
      const report = "There should be exactly one item with [DropdownButton]'s "
          'value\nDropdownButtonFormField<Supplier>';

      // Act / Assert
      expect(isSupplierPickerOverflow(report), isFalse);
    });
  });
}
