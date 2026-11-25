// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/order_summary.dart';
import 'package:pos/presentation/order/main/order_list_tile.dart';

OrderSummary _order() => OrderSummary(
      id: 'o1',
      code: 'OD_202611250007',
      customerCode: '',
      customerName: '',
      createdDate: '2026-11-25T10:00:00Z',
      total: 50,
      totalCost: 20,
      discount: 0,
      type: 'Store',
    );

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('a bill row shows its bill number above its time',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(OrderListTile(
        index: 0, order: _order(), showCost: true, onTap: () {})));

    // Assert
    final code = find.text('OD_202611250007');
    final time = find.text(_order().getCreatedDate());
    expect(code, findsOneWidget);
    expect(time, findsOneWidget);
    expect(tester.getTopLeft(code).dy, lessThan(tester.getTopLeft(time).dy));
    expect(find.text('50.00'), findsOneWidget);
    expect(find.text('ต้นทุน: 20.00  กำไร: 30.00'), findsOneWidget);
  });

  testWidgets('a bill row is read out by its visible text, not a hidden label',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(_host(OrderListTile(
        index: 0, order: _order(), showCost: false, onTap: () {})));

    // Assert
    expect(find.bySemanticsLabel(RegExp(r'^1 OD_202611250007')), findsNothing);
    expect(find.bySemanticsLabel(RegExp('OD_202611250007')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a bill row hides cost and profit from a non-admin',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(OrderListTile(
        index: 2, order: _order(), showCost: false, onTap: () {})));

    // Assert
    expect(find.text('OD_202611250007'), findsOneWidget);
    expect(find.textContaining('ต้นทุน'), findsNothing);
  });

  testWidgets('tapping a bill row opens that bill', (tester) async {
    // Arrange
    var opened = 0;
    await tester.pumpWidget(_host(OrderListTile(
        index: 0, order: _order(), showCost: false, onTap: () => opened++)));

    // Act
    await tester.tap(find.byType(ListTile));

    // Assert
    expect(opened, 1);
  });
}
