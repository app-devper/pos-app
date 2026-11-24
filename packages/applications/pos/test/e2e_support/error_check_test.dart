// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/error_check.dart';

const _noShopProfile = 'Error: ไม่พบข้อมูลที่ต้องการ [SY-404-002]';

void main() {
  group('unexpectedErrors', () {
    test('lets through the tolerated error code', () {
      // Act
      final unexpected =
          unexpectedErrors([_noShopProfile], tolerated: '[SY-404-002]');

      // Assert
      expect(unexpected, isEmpty);
    });

    test('does not let through another 404 code', () {
      // Act
      final unexpected = unexpectedErrors(
          ['Error: ไม่พบข้อมูลที่ต้องการ [SY-404-001]'],
          tolerated: '[SY-404-002]');

      // Assert
      expect(unexpected, hasLength(1));
    });

    test('does not hide a second error behind the tolerated one', () {
      // Act
      final unexpected = unexpectedErrors([_noShopProfile, 'Error: timeout'],
          tolerated: '[SY-404-002]');

      // Assert
      expect(unexpected, ['Error: timeout']);
    });

    test('lets nothing through when nothing is tolerated', () {
      // Act
      final unexpected = unexpectedErrors([_noShopProfile]);

      // Assert
      expect(unexpected, [_noShopProfile]);
    });
  });
}
