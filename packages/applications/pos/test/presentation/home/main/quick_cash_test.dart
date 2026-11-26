// The quick-cash amounts the payment dialog offers for a total.

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/quick_cash.dart';

void main() {
  test('a 50 total offers the next 20, then 100, 500 and 1000', () {
    expect(quickCashAmounts(50), [60, 100, 500, 1000]);
  });

  test('an 87.50 total offers 100, 500 and 1000 once each', () {
    expect(quickCashAmounts(87.50), [100, 500, 1000]);
  });

  test('a whole 100 total offers amounts above it, at most four', () {
    expect(quickCashAmounts(100), [120, 150, 200, 500]);
  });

  test('a zero total offers nothing', () {
    expect(quickCashAmounts(0), isEmpty);
  });

  test('a negative total offers nothing', () {
    expect(quickCashAmounts(-5), isEmpty);
  });

  test('a large total offers distinct amounts above it, at most four', () {
    // Act
    final amounts = quickCashAmounts(999999);

    // Assert
    expect(amounts, isNotEmpty);
    expect(amounts.length, lessThanOrEqualTo(4));
    expect(amounts.every((a) => a > 999999), isTrue);
    expect(amounts.toSet().length, amounts.length);
  });

  test('a total a few satang under a step rounds up to that step', () {
    expect(quickCashAmounts(59.99), [60, 100, 500, 1000]);
  });

  test('the amounts cannot be changed by the caller', () {
    expect(() => quickCashAmounts(50).add(1), throwsUnsupportedError);
  });
}
