// The cart column of the selling screen: header, lines as cards, the
// customer and controlled-drug cards, the totals and the one pay button.

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/presentation/home/main/cart_panel.dart';
import 'package:pos/presentation/home/main/cart_widget.dart';

import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';

Future<List<String>> _pump(
  WidgetTester tester, {
  int lines = 0,
  double total = 0,
  Size size = const Size(400, 800),
  double textScale = 1,
  IndexedWidgetBuilder? lineBuilder,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final events = <String>[];
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: const [thaiLanguages],
    home: MediaQuery(
      data: MediaQueryData(
          size: size, textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: CartPanel(
          cartNumber: 2,
          lineCount: lines,
          lineBuilder: lineBuilder ??
              (context, i) => SizedBox(
            height: 56,
            child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('บรรทัด $i')),
              ),
          total: total,
          customer: null,
          complianceSummary: null,
          onChooseCustomer: () => events.add('customer'),
          onRemoveCustomer: () => events.add('remove-customer'),
          onCompliance: () => events.add('compliance'),
          onPay: () => events.add('pay'),
        ),
      ),
    ),
  ));
  return events;
}

Finder _cardAround(Finder inner) =>
    find.ancestor(of: inner, matching: find.byType(AppCard));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('names the open cart', (tester) async {
    await _pump(tester);

    expect(find.text('ตะกร้าสินค้า #2'), findsOneWidget);
  });

  testWidgets('an empty cart cannot be paid and says how to start',
      (tester) async {
    final events = await _pump(tester);

    expect(find.text('เลือกสินค้าเพื่อเริ่มขาย'), findsOneWidget);
    await tester.tap(find.text('เลือกสินค้าเพื่อเริ่มขาย'));
    expect(events, isEmpty);
  });

  testWidgets('with lines, the one filled button pays the total',
      (tester) async {
    final events = await _pump(tester, lines: 2, total: 50);

    expect(find.text('ชำระเงิน (2 รายการ)'), findsOneWidget);
    expect(find.byType(ElevatedButton).evaluate().length +
        find.byType(FilledButton).evaluate().length, 1);

    await tester.tap(find.text('ชำระเงิน (2 รายการ)'));
    expect(events, ['pay']);
  });

  testWidgets('the totals read as one line each, label then amount',
      (tester) async {
    await _pump(tester, lines: 1, total: 50);

    expect(tester.getSemantics(find.text('ยอดรวมสุทธิ')).label,
        'ยอดรวมสุทธิ\n฿50.00');
    expect(tester.getSemantics(find.text('ราคาเฉพาะสินค้า')).label,
        'ราคาเฉพาะสินค้า\n฿50.00');
    expect(tester.getSemantics(find.text('ส่วนลด (%)')).label, 'ส่วนลด (%)\n-');
    final total = tester.widget<Text>(find.byKey(CartPanel.netTotalKey));
    expect(total.data, '฿50.00');
    expect(total.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()));
  });

  testWidgets('the customer and the controlled-drug rows are cards, in the '
      'product\'s neutral colours', (tester) async {
    final events = await _pump(tester);

    expect(_cardAround(find.text('ข้อมูลลูกค้า')), findsOneWidget);
    expect(_cardAround(find.text('ข้อมูลยาควบคุม')), findsOneWidget);
    for (final avatar
        in tester.widgetList<CircleAvatar>(find.byType(CircleAvatar))) {
      expect(avatar.backgroundColor, AppColors.light.surfaceSunken);
      expect(avatar.foregroundColor, AppColors.light.textPrimary);
    }

    await tester.tap(find.text('ข้อมูลลูกค้า'));
    await tester.tap(find.text('ข้อมูลยาควบคุม'));
    expect(events, ['customer', 'compliance']);
  });

  testWidgets('each line is a card of its own, with no rule between them',
      (tester) async {
    await _pump(tester, lines: 3, total: 30);

    for (var i = 0; i < 3; i++) {
      expect(_cardAround(find.text('บรรทัด $i')), findsOneWidget);
    }
    final first = tester.getRect(_cardAround(find.text('บรรทัด 0')));
    final second = tester.getRect(_cardAround(find.text('บรรทัด 1')));
    expect(second.top - first.bottom, greaterThan(0));
  });

  testWidgets('on a short phone at a large text size the pay button stays '
      'on screen and the rest scrolls', (tester) async {
    await _pump(tester,
        lines: 12, total: 120, size: const Size(340, 640), textScale: 1.3);

    expect(tester.takeException(), isNull);
    final pay = tester.getRect(find.text('ชำระเงิน (12 รายการ)'));
    expect(pay.bottom, lessThanOrEqualTo(640));
    expect(find.text('บรรทัด 11').hitTestable(), findsNothing);
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('a real line in its card: its round buttons and its splash '
      'paint inside the card, and it draws no rule of its own', (tester) async {
    await _pump(
      tester,
      lines: 1,
      total: 20,
      lineBuilder: (context, i) => CartOrderItem(
        title: 'พาราเซตามอล',
        quantity: 2,
        price: 10,
        unit: 'แผง',
        discount: 0,
        priceDetail: 'ราคาปลีก',
        allowOversell: false,
        onToggleOversell: () {},
        onRemove: () {},
        onAdd: () {},
        onEdit: () {},
        onEditPrice: () {},
      ),
    );

    final card = _cardAround(find.byType(CartOrderItem));
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.byType(Divider)),
        findsNothing);
    final ink = find.descendant(of: card, matching: find.byType(Ink));
    expect(ink, findsWidgets);
    final material =
        find.ancestor(of: ink.first, matching: find.byType(Material)).first;
    expect(find.descendant(of: card, matching: material), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone on its side overflows nothing; the totals scroll into '
      'view under the lines', (tester) async {
    await _pump(tester, lines: 2, total: 20, size: const Size(340, 300));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('ชำระเงิน (2 รายการ)').hitTestable(),
        findsOneWidget);
    await tester.ensureVisible(find.text('ยอดรวมสุทธิ'));
    await tester.pumpAndSettle();
    expect(find.text('ยอดรวมสุทธิ').hitTestable(), findsOneWidget);
  });

  testWidgets('with few lines the totals sit at the foot, by the pay button',
      (tester) async {
    await _pump(tester, lines: 1, total: 10);

    final total = tester.getRect(find.text('ยอดรวมสุทธิ'));
    final pay = tester.getRect(find.textContaining('ชำระเงิน (1 รายการ)'));
    expect(pay.top - total.bottom, lessThan(60));
  });
}
