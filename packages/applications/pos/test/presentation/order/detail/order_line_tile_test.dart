// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/presentation/order/detail/order_line_tile.dart';

OrderItemDetail _line({String status = 'CONFIRMED'}) => OrderItemDetail(
      id: 'i1',
      product: null,
      quantity: 2,
      price: 40,
      costPrice: 16,
      discount: 0,
      createdDate: '2026-11-26T10:00:00Z',
      order: null,
      status: status,
    );

Widget _host(OrderItemDetail line, {bool isAdmin = true}) => MaterialApp(
      home: Scaffold(
        body: OrderLineTile(
          line: line,
          isAdmin: isAdmin,
          onTap: () {},
          onDelete: () {},
          onHistory: () {},
          onReturn: () {},
        ),
      ),
    );

void main() {
  testWidgets('a cancelled line is marked and offers an admin no action',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(_line(status: 'CANCELLED')));

    // Assert
    expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.history), findsNothing);
    expect(find.byIcon(Icons.keyboard_return), findsNothing);
    final amount = tester.widget<Text>(find.text('40.00'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('a line that is not cancelled offers an admin its actions',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(_line()));

    // Assert
    expect(find.text('ยกเลิกแล้ว'), findsNothing);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_return), findsOneWidget);
    final amount = tester.widget<Text>(find.text('40.00'));
    expect(amount.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('a cancelled line is marked for a non-admin too', (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(_line(status: 'CANCELLED'), isAdmin: false));

    // Assert
    expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
