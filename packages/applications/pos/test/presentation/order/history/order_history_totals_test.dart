// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/presentation/order/core/export_csv.dart';
import 'package:pos/presentation/order/history/order_history_state.dart';
import 'package:pos/presentation/order/history/order_history_tile.dart';

OrderItemDetail _line(String id,
        {required double price, required double cost, String status = ''}) =>
    OrderItemDetail(
      id: id,
      product: null,
      quantity: 1,
      price: price,
      costPrice: cost,
      discount: 0,
      createdDate: '2026-11-26T10:00:00Z',
      order: null,
      status: status,
    );

final _sold = _line('sold', price: 30, cost: 10, status: 'CONFIRMED');
final _cancelled = _line('cancelled', price: 20, cost: 8, status: 'CANCELLED');

Widget _host(OrderItemDetail line) => MaterialApp(
      home: Scaffold(body: OrderHistoryTile(line: line, showCost: true)),
    );

void main() {
  group('a product\'s sales history', () {
    test('a cancelled line counts in neither the total, the cost nor profit',
        () {
      // Arrange
      final state = OrderHistoryState(items: [_sold, _cancelled]);

      // Act
      final total = state.total;
      final cost = state.totalCost;

      // Assert
      expect(state.items, hasLength(2), reason: 'both lines stay listed');
      expect(total, 30);
      expect(cost, 10);
      expect(total - cost, 20);
    });

    testWidgets('a cancelled line is marked and its amount struck through',
        (tester) async {
      // Arrange / Act
      await tester.pumpWidget(_host(_cancelled));

      // Assert
      expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
      final amount = tester.widget<Text>(find.text('20.00'));
      expect(amount.style?.decoration, TextDecoration.lineThrough);
      expect(find.text('ต้นทุน: 8.00  กำไร: 12.00'), findsOneWidget);
    });

    testWidgets('a sold line is not marked', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(_host(_sold));

      // Assert
      expect(find.text('ยกเลิกแล้ว'), findsNothing);
      expect(tester.widget<Text>(find.text('30.00')).style?.decoration,
          isNot(TextDecoration.lineThrough));
    });

    test('the CSV export leaves a cancelled line out', () {
      // Arrange / Act
      final rows = ExportCsv.orderItemRows([_sold, _cancelled]);

      // Assert
      expect(rows, hasLength(2), reason: 'the header and the sold line');
      expect(rows.last[0], 1);
      expect(rows.last[6], 30);
    });
  });
}
