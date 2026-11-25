// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/presentation/order/detail/order_detail_header.dart';

OrderDetail _bill({String status = 'CONFIRMED'}) => OrderDetail(
      id: 'order-1',
      createdDate: '2026-11-26T10:00:00Z',
      items: const [],
      total: 0,
      totalCost: 0,
      discount: 0,
      type: 'Cash',
      code: 'OD_1',
      customerCode: '',
      customerName: '',
      status: status,
    );

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(appBar: AppBar(), body: child));

Widget _actions(OrderDetail? bill, {bool isAdmin = true}) => _host(Row(
      children: [
        OrderDetailActions(
          bill: bill,
          isAdmin: isAdmin,
          onPrint: () {},
          onSync: () {},
          onReturns: () {},
          onDelete: () {},
        ),
      ],
    ));

void main() {
  group('the bill detail header', () {
    testWidgets('a cancelled bill is marked ยกเลิกแล้ว', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(
          _host(OrderDetailHeader(bill: _bill(status: 'CANCELLED'))));

      // Assert
      expect(find.textContaining('OD_1'), findsOneWidget);
      expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
    });

    testWidgets('a bill that is not cancelled carries no mark', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(_host(OrderDetailHeader(bill: _bill())));

      // Assert
      expect(find.textContaining('OD_1'), findsOneWidget);
      expect(find.text('ยกเลิกแล้ว'), findsNothing);
    });
  });

  group('the bill detail actions', () {
    testWidgets('an admin may delete a bill that is not cancelled',
        (tester) async {
      // Arrange / Act
      await tester.pumpWidget(_actions(_bill()));

      // Assert
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('a cancelled bill offers no delete, even to an admin',
        (tester) async {
      // Arrange / Act
      await tester.pumpWidget(_actions(_bill(status: 'CANCELLED')));

      // Assert
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('a non-admin gets only the receipt', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(_actions(_bill(), isAdmin: false));

      // Assert
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.sync), findsNothing);
    });
  });
}
