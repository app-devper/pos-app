// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/order/detail/order_line_tile.dart';
import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';

OrderItemDetail _line(
        {String status = 'CONFIRMED',
        int returnedQty = 0,
        String name = 'tea'}) =>
    OrderItemDetail(
      id: 'i1',
      product: Product(
        id: 'p1',
        name: name,
        status: 'ACTIVE',
        category: 'General',
        createdDate: '',
        units: const [],
        prices: const [],
        stocks: const [],
      ),
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
Widget _host(OrderItemDetail line,
        {bool isAdmin = true, bool billCancelled = false}) =>
    MaterialApp(
      localizationsDelegates: const [thaiLanguages],
      theme: ThemeData(visualDensity: VisualDensity.compact),
      home: Scaffold(
        body: OrderLineTile(
          line: line,
          billCancelled: billCancelled,
          isAdmin: isAdmin,
          onTap: () {},
          onDelete: () {},
          onHistory: () {},
          onReturn: () {},
        ),
      ),
    );

/// The line's menu, named for the line.
const _menuName = 'คำสั่งเพิ่มเติมของ 2x tea ฿40.00';

/// [line] in the app's theme and fonts on a 360 px phone, for an admin,
/// with each action counted in [taps].
Widget _phoneHost(OrderItemDetail line, Map<String, int> taps) => MaterialApp(
      theme: CustomTheme.mainTheme,
      localizationsDelegates: const [thaiLanguages],
      home: Scaffold(
        body: ListView(children: [
          OrderLineTile(
            line: line,
            isAdmin: true,
            onTap: () {},
            onDelete: () =>
                taps.update('delete', (n) => n + 1, ifAbsent: () => 1),
            onHistory: () =>
                taps.update('history', (n) => n + 1, ifAbsent: () => 1),
            onReturn: () =>
                taps.update('return', (n) => n + 1, ifAbsent: () => 1),
          ),
        ]),
      ),
    );

void main() {
  group('the line\'s look on a phone', () {
    setUpAll(loadAppFonts);

    testWidgets('a 30-character product name is shown in full at 360 px',
        (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);
      const name = 'Paracetamol 500 mg tablets x10';
      expect(name.length, 30);

      // Act
      await tester.pumpWidget(_phoneHost(_line(name: name), {}));

      // Assert
      expect(tester.takeException(), isNull);
      final title = tester.renderObject<RenderParagraph>(find.text(name));
      expect(title.didExceedMaxLines, isFalse);
      expect(tester.widget<Text>(find.text(name)).maxLines, 2);
    });

    testWidgets('the quantity leads as 2× and the amount ends the row, bold',
        (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);

      // Act
      await tester.pumpWidget(_phoneHost(_line(), {}));

      // Assert
      final quantity = tester.getCenter(find.text('2×'));
      final name = tester.getCenter(find.text('tea'));
      final amount = find.text('40.00');
      expect(quantity.dx, lessThan(name.dx));
      expect(tester.getCenter(amount).dx, greaterThan(name.dx));
      final style = tester.widget<Text>(amount).style!;
      expect(style.fontWeight, FontWeight.bold);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    testWidgets(
        'the line\'s three actions are in its menu, by their names, '
        'delete red and last', (tester) async {
      // Arrange
      final semantics = tester.ensureSemantics();
      useViewSize(tester, phoneSize);
      final taps = <String, int>{};
      await tester.pumpWidget(_phoneHost(_line(), taps));
      expect(find.byIcon(Icons.delete), findsNothing);

      // Act / Assert: each item, chosen from the menu, calls its action
      for (final (label, action) in [
        ('คืนสินค้า 2x tea ฿40.00', 'return'),
        ('ประวัติการขาย 2x tea ฿40.00', 'history'),
        ('ลบรายการ 2x tea ฿40.00', 'delete'),
      ]) {
        await tester.tap(find.byTooltip(_menuName));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
        if (action == 'delete') {
          final error =
              Theme.of(tester.element(find.text('ลบรายการ'))).colorScheme.error;
          expect(
              tester.widget<Text>(find.text('ลบรายการ')).style?.color, error);
          expect(tester.getTopLeft(find.text('ลบรายการ')).dy,
              greaterThan(tester.getTopLeft(find.text('คืนสินค้า')).dy));
          expect(find.byType(PopupMenuDivider), findsOneWidget);
        }
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pumpAndSettle();
        expect(taps[action], 1, reason: label);
      }
      semantics.dispose();
    });

    testWidgets('a line with nothing left to return offers no return',
        (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);
      await tester.pumpWidget(_phoneHost(_line(returnedQty: 2), {}));

      // Act
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ประวัติการขาย'), findsOneWidget);
      expect(find.text('คืนสินค้า'), findsNothing);
    });
  });

  testWidgets('a cancelled line is marked and offers an admin no action',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(_line(status: 'CANCELLED')));

    // Assert
    expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    final amount = tester.widget<Text>(find.text('40.00'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets(
      'a line of a cancelled bill is marked and offers an admin no action, '
      'even when the line itself is not marked cancelled', (tester) async {
    // Arrange / Act: older data, the bill cancelled and its line left ACTIVE
    await tester
        .pumpWidget(_host(_line(status: 'ACTIVE'), billCancelled: true));

    // Assert
    expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    final amount = tester.widget<Text>(find.text('40.00'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('a line that is not cancelled offers an admin its actions',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(_line()));

    // Assert
    expect(find.text('ยกเลิกแล้ว'), findsNothing);
    expect(find.byTooltip(_menuName), findsOneWidget);
    final amount = tester.widget<Text>(find.text('40.00'));
    expect(amount.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('a cancelled line is marked for a non-admin too', (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(_line(status: 'CANCELLED'), isAdmin: false));

    // Assert
    expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
    expect(find.text('2×'), findsOneWidget);
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
