// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/run_data.dart';

const _runId = '20261124153012-4242';
const _runIdOneSecondLater = '20261124153013-4242';

void main() {
  group('RunData.nameIn', () {
    test('prefixes what the data is with E2E and the run id', () {
      // Act
      final name = RunData.nameIn(_runId, 'product');

      // Assert
      expect(name, 'E2E-20261124153012-4242 product');
    });
  });

  group('RunData.barcodeIn', () {
    test('is 13 digits', () {
      // Act
      final barcode = RunData.barcodeIn(_runId, 1);

      // Assert
      expect(barcode, matches(RegExp(r'^\d{13}$')));
    });

    test('is the same for the same run and number', () {
      // Act
      final first = RunData.barcodeIn(_runId, 7);
      final again = RunData.barcodeIn(_runId, 7);

      // Assert
      expect(again, first);
    });

    test('differs for every number within a run', () {
      // Act
      final barcodes = {
        for (var n = 1; n <= RunData.maxBarcodes; n++)
          RunData.barcodeIn(_runId, n),
      };

      // Assert
      expect(barcodes, hasLength(RunData.maxBarcodes));
    });

    test('differs between runs started one second apart', () {
      // Act
      final earlier = {
        for (var n = 1; n <= RunData.maxBarcodes; n++)
          RunData.barcodeIn(_runId, n),
      };
      final later = {
        for (var n = 1; n <= RunData.maxBarcodes; n++)
          RunData.barcodeIn(_runIdOneSecondLater, n),
      };

      // Assert
      expect(earlier.intersection(later), isEmpty);
    });

    test('refuses a number outside 1..maxBarcodes', () {
      // Act / Assert
      expect(() => RunData.barcodeIn(_runId, 0), throwsArgumentError);
      expect(
        () => RunData.barcodeIn(_runId, RunData.maxBarcodes + 1),
        throwsArgumentError,
      );
    });

    test('refuses a run id that does not start with a timestamp', () {
      // Act / Assert
      expect(() => RunData.barcodeIn('local-run', 1), throwsArgumentError);
    });
  });

  group('runNamePattern', () {
    test('matches every name RunData gives', () {
      for (final what in ['product', 'sale customer', 'stock count']) {
        expect(
            RunData.runNamePattern
                .hasMatch(RunData.nameIn('20261125120303-38502', what)),
            isTrue,
            reason: what);
      }
    });

    test('does not match other E2E-looking names', () {
      for (final name in [
        'E2E-shirt',
        'E2E customer',
        'E2E supplier',
        'E2E-2026 product',
        'xE2E-20261125120303-38502 product',
      ]) {
        expect(RunData.runNamePattern.hasMatch(name), isFalse, reason: name);
      }
    });
  });
}
