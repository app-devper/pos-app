// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/order_summary.dart';
import 'package:pos/presentation/order/main/order_list_tile.dart';
import '../../../support/app_fonts.dart';

OrderSummary _order({String status = 'CONFIRMED'}) => OrderSummary(
      id: 'o1',
      code: 'OD_202611250007',
      customerCode: '',
      customerName: '',
      createdDate: '2026-11-25T10:00:00Z',
      total: 50,
      totalCost: 20,
      discount: 0,
      type: 'Store',
      status: status,
    );

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

/// In the app's theme and fonts, so sizes and colours are the user's.
Widget _appHost(Widget child) =>
    MaterialApp(theme: CustomTheme.mainTheme, home: Scaffold(body: child));

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
    expect(find.text('฿50.00'), findsOneWidget);
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

  testWidgets('a cancelled bill row is marked and its amount struck through',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(OrderListTile(
        index: 0,
        order: _order(status: 'CANCELLED'),
        showCost: true,
        onTap: () {})));

    // Assert
    expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
    final amount = tester.widget<Text>(find.text('฿50.00'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('a bill row that is not cancelled carries no mark',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(OrderListTile(
        index: 0, order: _order(), showCost: true, onTap: () {})));

    // Assert
    expect(find.text('ยกเลิกแล้ว'), findsNothing);
    final amount = tester.widget<Text>(find.text('฿50.00'));
    expect(amount.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  group('the bill row\'s look', () {
    setUpAll(loadAppFonts);

    double fontSizeOf(WidgetTester tester, Finder text) =>
        tester.renderObject<RenderParagraph>(text).text.style!.fontSize!;

    testWidgets('the amount is the row\'s largest text, after a ฿',
        (tester) async {
      // Arrange / Act
      await tester.pumpWidget(_appHost(OrderListTile(
          index: 0, order: _order(), showCost: true, onTap: () {})));

      // Assert
      final amount = fontSizeOf(tester, find.text('฿50.00'));
      expect(
          amount,
          greaterThan(
              fontSizeOf(tester, find.text('ต้นทุน: 20.00  กำไร: 30.00'))));
      expect(amount,
          greaterThan(fontSizeOf(tester, find.text('OD_202611250007'))));
      final style = tester.widget<Text>(find.text('฿50.00')).style!;
      expect(style.fontWeight, FontWeight.bold);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    testWidgets('the row number is a muted label of at least 12 sp',
        (tester) async {
      // Arrange / Act
      await tester.pumpWidget(_appHost(OrderListTile(
          index: 0, order: _order(), showCost: true, onTap: () {})));

      // Assert
      final number = find.text('1');
      expect(fontSizeOf(tester, number), greaterThanOrEqualTo(12));
      final colour =
          tester.renderObject<RenderParagraph>(number).text.style!.color;
      expect(colour, AppColors.light.textSecondary);
    });

    testWidgets(
        'a million-baht row fits 320 px at 1.3× text, cost and profit shown',
        (tester) async {
      // Arrange
      useViewSize(tester, const Size(320, 640));
      final big = OrderSummary(
        id: 'o1',
        code: 'OD_202611250007',
        customerCode: 'C1',
        customerName: 'สมชาย ใจดี',
        createdDate: '2026-11-25T10:00:00Z',
        total: 1234567,
        totalCost: 1000000,
        discount: 0,
        type: 'Store',
        status: 'CANCELLED',
      );

      // Act
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_appHost(ListView(children: [
        OrderListTile(index: 99, order: big, showCost: true, onTap: () {}),
      ])));

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.text('฿1,234,567.00'), findsOneWidget);
      final amount =
          tester.renderObject<RenderParagraph>(find.text('฿1,234,567.00'));
      expect(amount.didExceedMaxLines, isFalse);
    });
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
