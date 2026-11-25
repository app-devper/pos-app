// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/presentation/order/detail/order_line_tile.dart';
import '../../../support/app_languages.dart';

OrderItemDetail _line({String status = 'CONFIRMED', int returnedQty = 0}) =>
    OrderItemDetail(
      id: 'i1',
      product: null,
      quantity: 2,
      price: 40,
      costPrice: 16,
      discount: 0,
      createdDate: '2026-11-26T10:00:00Z',
      order: null,
      status: status,
      returnedQty: returnedQty,
    );

/// Compact, the app's density on desktop and the web, where the E2E suite
/// saw a cancelled, returned line overflow its row.
Widget _host(OrderItemDetail line, {bool isAdmin = true}) => MaterialApp(
      localizationsDelegates: const [thaiLanguages],
      theme: ThemeData(visualDensity: VisualDensity.compact),
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

  testWidgets('a cancelled line with a return fits its row', (tester) async {
    for (final isAdmin in [true, false]) {
      // Arrange / Act: the E2E bill's line, 1 of 2 returned, then cancelled
      await tester.pumpWidget(
          _host(_line(status: 'CANCELLED', returnedQty: 1), isAdmin: isAdmin));

      // Assert: no overflow was reported while laying it out
      expect(tester.takeException(), isNull, reason: 'admin: $isAdmin');
      expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
      expect(find.text('คืน 1'), findsOneWidget);
    }
  });
}
