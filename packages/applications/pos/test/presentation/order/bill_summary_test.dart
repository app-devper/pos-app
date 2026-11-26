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

  // On the web a text merged into a node with children is written as an
  // aria-label only, which Maestro cannot read: each row of the foot is a
  // leaf node of its own (the bills list merged its foot into the page).
  testWidgets('each row of the foot is one node of its own', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(_host(Semantics(
        container: true,
        child: const BillSummary(total: 950, totalCost: 380, showCost: true))));

    // Assert
    for (final row in ['ยอดรวม ฿ 950.00', 'ต้นทุน ฿ 380.00', 'กำไร ฿ 570.00']) {
      final node = tester.getSemantics(find.bySemanticsLabel(row));
      expect(node.childrenCount, 0, reason: row);
    }
    semantics.dispose();
  });
}
