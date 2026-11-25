// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/order/bill_summary.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('an admin reads the total, cost and profit in Thai',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(
        _host(const BillSummary(total: 75, totalCost: 30, showCost: true)));

    // Assert
    expect(find.text('ยอดรวม'), findsOneWidget);
    expect(find.text('฿ 75.00'), findsOneWidget);
    expect(find.text('ต้นทุน'), findsOneWidget);
    expect(find.text('฿ 30.00'), findsOneWidget);
    expect(find.text('กำไร'), findsOneWidget);
    expect(find.text('฿ 45.00'), findsOneWidget);
    expect(find.textContaining('Total'), findsNothing);
  });

  testWidgets('anyone else reads only the total', (tester) async {
    // Arrange / Act
    await tester.pumpWidget(
        _host(const BillSummary(total: 75, totalCost: 30, showCost: false)));

    // Assert
    expect(find.text('ยอดรวม'), findsOneWidget);
    expect(find.text('ต้นทุน'), findsNothing);
    expect(find.text('กำไร'), findsNothing);
  });

  test('a line reads its cost and profit in Thai', () {
    // Act
    final text = costAndProfitText(cost: 20, profit: 30);

    // Assert
    expect(text, 'ต้นทุน: 20.00  กำไร: 30.00');
  });
}
