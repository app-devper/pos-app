// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/presentation/order/detail/order_detail_header.dart';
import '../../../support/app_languages.dart';

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

Widget _host(Widget child) => MaterialApp(
    localizationsDelegates: const [thaiLanguages],
    home: Scaffold(appBar: AppBar(), body: child));

Widget _actions(OrderDetail? bill,
        {bool isAdmin = true,
        VoidCallback? onReturns,
        VoidCallback? onDelete}) =>
    _host(Row(
      children: [
        OrderDetailActions(
          bill: bill,
          isAdmin: isAdmin,
          onPrint: () {},
          onSync: () {},
          onReturns: onReturns ?? () {},
          onDelete: onDelete ?? () {},
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
    /// The bill's command menu, by its name.
    final menu = find.byTooltip('คำสั่งเพิ่มเติมของบิล');

    testWidgets(
        'an admin gets the receipt and reload as icons, and the returns '
        'history and a red delete, apart, in the bill\'s menu', (tester) async {
      // Arrange
      await tester.pumpWidget(_actions(_bill()));
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsNothing);

      // Act
      await tester.tap(menu);
      await tester.pumpAndSettle();

      // Assert
      final items = tester
          .widgetList<PopupMenuEntry<Object?>>(
              find.byWidgetPredicate((w) => w is PopupMenuEntry))
          .toList();
      expect(items, hasLength(3));
      expect(items[1], isA<PopupMenuDivider>());
      expect(find.text('ประวัติการคืนสินค้า'), findsOneWidget);
      final delete = tester.widget<Text>(find.text('ลบบิล'));
      final error =
          Theme.of(tester.element(find.text('ลบบิล'))).colorScheme.error;
      expect(delete.style?.color, error);
      final returnsTop = tester.getTopLeft(find.text('ประวัติการคืนสินค้า')).dy;
      expect(tester.getTopLeft(find.text('ลบบิล')).dy, greaterThan(returnsTop));
    });

    testWidgets('the menu\'s items call their actions', (tester) async {
      // Arrange
      var returns = 0;
      var deletes = 0;
      await tester.pumpWidget(_actions(_bill(),
          onReturns: () => returns++, onDelete: () => deletes++));

      // Act
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ประวัติการคืนสินค้า'));
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลบบิล'));
      await tester.pumpAndSettle();

      // Assert
      expect(returns, 1);
      expect(deletes, 1);
    });

    testWidgets('a cancelled bill\'s menu offers no delete, even to an admin',
        (tester) async {
      // Arrange
      await tester.pumpWidget(_actions(_bill(status: 'CANCELLED')));

      // Act
      await tester.tap(menu);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ประวัติการคืนสินค้า'), findsOneWidget);
      expect(find.text('ลบบิล'), findsNothing);
      expect(find.byType(PopupMenuDivider), findsNothing);
    });

    testWidgets('a non-admin gets only the receipt, and no menu',
        (tester) async {
      // Arrange / Act
      await tester.pumpWidget(_actions(_bill(), isAdmin: false));

      // Assert
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(menu, findsNothing);
    });
  });
}
