// The selling screen on a phone: the products come first, the open cart is
// a bar along the foot, and the cart itself opens over them.

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/container.dart';
import 'package:pos/presentation/home/main/cart_bar.dart';
import 'package:pos/presentation/home/main/cart_page.dart';
import 'package:pos/presentation/home/main/cart_panel.dart';
import 'package:pos/presentation/home/main/cart_widget.dart';
import 'package:pos/presentation/home/main/product_card.dart';

import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';
import 'cart_page_sale_test.dart' show registerSellingScreen;

const _phone = Size(390, 844);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(WidgetTester tester, {Size size = _phone}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  registerSellingScreen('OD_202611280001');
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: const [thaiLanguages],
    home: const Scaffold(body: CartPage()),
  ));
  await _settle(tester);
}

Finder get _bar => find.byType(CartBar);
Finder get _sheet => find.byKey(CartPage.cartSheetKey);

Future<void> _openCart(WidgetTester tester) async {
  await tester.tap(_bar);
  await _settle(tester);
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  testWidgets('the products are on the screen; the empty cart is a bar',
      (tester) async {
    await _open(tester);

    expect(find.byType(ProductCard), findsOneWidget);
    expect(find.byType(CartPanel), findsNothing);
    expect(_bar, findsOneWidget);
    expect(find.descendant(of: _bar, matching: find.text('ตะกร้าสินค้า #1')),
        findsOneWidget);
    expect(find.descendant(of: _bar, matching: find.text('ว่าง')),
        findsOneWidget);
    expect(tester.getSemantics(_bar).label, 'ตะกร้าสินค้า #1\nว่าง');
    final bar = tester.getRect(_bar);
    expect(bar.bottom, lessThanOrEqualTo(_phone.height));
    expect(bar.top, greaterThan(tester.getRect(find.byType(ProductCard)).bottom));
  });

  testWidgets('a product tapped goes into the cart; the bar says how much',
      (tester) async {
    await _open(tester);

    await tester.tap(find.byType(ProductCard));
    await _settle(tester);

    expect(find.text('ในตะกร้า 1'), findsOneWidget);
    expect(tester.getSemantics(_bar).label,
        'ตะกร้าสินค้า #1\n1 รายการ ฿10.00');
  });

  testWidgets('the bar opens the cart over the products; ปิด closes it',
      (tester) async {
    await _open(tester);
    await tester.tap(find.byType(ProductCard));
    await _settle(tester);

    await _openCart(tester);

    expect(_sheet, findsOneWidget);
    expect(find.byType(CartPanel), findsOneWidget);
    expect(find.text('ยอดรวมสุทธิ'), findsOneWidget);
    expect(find.byType(CartItem), findsWidgets,
        reason: 'the other carts are reached from the cart');
    expect(find.byType(CartOrderItem), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ปิด'));
    await _settle(tester);
    expect(_sheet, findsNothing);
    expect(find.byType(ProductCard), findsOneWidget);
  });

  testWidgets('the open cart follows the cart: + adds one more',
      (tester) async {
    await _open(tester);
    await tester.tap(find.byType(ProductCard));
    await _settle(tester);
    await _openCart(tester);

    await tester.tap(find.bySemanticsLabel(RegExp('^เพิ่มจำนวน ')).first);
    await _settle(tester);

    expect(find.textContaining('ชำระเงิน (1 รายการ)'), findsOneWidget);
    expect(find.text('฿20.00'), findsWidgets);
  });

  testWidgets('system Back with the cart open closes only the cart',
      (tester) async {
    await _open(tester);
    await _openCart(tester);

    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(_sheet, findsNothing);
    expect(_bar, findsOneWidget);
  });

  testWidgets('a sale paid from the cart closes it, back to the products',
      (tester) async {
    await _open(tester);
    await tester.tap(find.byType(ProductCard));
    await _settle(tester);
    await _openCart(tester);

    await tester.tap(find.textContaining('ชำระเงิน ('));
    await _settle(tester);
    await tester.tap(find.bySemanticsLabel('รับชำระพอดี ไม่มีเงินทอน'));
    await _settle(tester);

    expect(_sheet, findsNothing);
    expect(find.text('ขายสำเร็จ เลขที่บิล OD_202611280001'), findsOneWidget);
    expect(tester.getSemantics(_bar).label, 'ตะกร้าสินค้า #1\nว่าง');
  });

  testWidgets('a tablet keeps the cart beside the products, with no bar',
      (tester) async {
    await _open(tester, size: const Size(768, 1024));

    expect(find.byType(CartPanel), findsOneWidget);
    expect(_bar, findsNothing);
  });

  testWidgets('a 360 x 640 phone at a large text size overflows nothing',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, size: const Size(360, 640));
    await tester.tap(find.byType(ProductCard));
    await _settle(tester);
    await _openCart(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('ชำระเงิน ('), findsOneWidget);
  });
}
