// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/product/main/product_stock_card.dart';
import '../../support/app_fonts.dart';
import '../../support/app_languages.dart';

/// A lot number as long as the E2E suite's.
const _longLot = 'L20261126041051-86725';

final _price = ProductPrice(
    id: 'pr1',
    unitId: 'u1',
    productId: 'p1',
    price: 10,
    customerType: 'General');

Widget _card(List<ProductStock> stocks) => MaterialApp(
      localizationsDelegates: const [thaiLanguages],
      theme: CustomTheme.mainTheme,
      home: Scaffold(
        body: ListView(children: [
          ProductStockCard(
            unit: _unit,
            stocks: stocks,
            price: _price,
            onSequence: () {},
            onAdd: () {},
            onEdit: (_) {},
            onQuantity: (_) {},
            onAdjust: (_) {},
          ),
        ]),
      ),
    );

final _unit = ProductUnit(
  id: 'u1',
  productId: 'p1',
  costPrice: 5,
  unit: 'ชิ้น',
  size: 1,
  barcode: '',
  volume: 0,
  volumeUnit: '',
);

ProductStock _lot(String id, String lot, int quantity) => ProductStock(
      id: id,
      unitId: 'u1',
      productId: 'p1',
      receiveCode: '',
      sequence: 1,
      lotNumber: lot,
      costPrice: 5,
      price: 10,
      import: quantity,
      quantity: quantity,
      expireDate: '2030-01-31T00:00:00Z',
      importDate: '2026-11-26T00:00:00Z',
    );

void main() {
  setUpAll(loadAppFonts);

  for (final size in [phoneSize, desktopSize]) {
    testWidgets('a long lot number fits the stock row, readable whole, $size',
        (tester) async {
      // Arrange
      useViewSize(tester, size);

      // Act
      await tester.pumpWidget(_card([
        _lot('s1', _longLot, 1200),
        _lot('s2', 'L2026B', 3),
      ]));
      await tester.ensureVisible(find.text(_longLot));
      await tester.pumpAndSettle();

      // Assert: nothing overflows; the number is on one line, unclipped, on
      // the card once in view; every column's heading is there to read
      expect(tester.takeException(), isNull);
      final lot = tester.renderObject<RenderParagraph>(find.text(_longLot));
      expect(lot.didExceedMaxLines, isFalse);
      expect(lot.size.height, lessThan(30), reason: 'one line');
      expectInside(tester, find.text(_longLot), find.byType(Card));
      for (final heading in [
        'นำเข้าเมื่อ',
        'ล็อต',
        'วันหมดอายุ',
        'ต้นทุน',
        'ราคาขาย',
        'นำเข้า',
        'คงเหลือ'
      ]) {
        await tester.ensureVisible(find.text(heading));
        await tester.pumpAndSettle();
        expectInside(tester, find.text(heading), find.byType(Card));
      }
    });
  }

  testWidgets('the stock tab shows each lot\'s number', (tester) async {
    // Arrange
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final adjusted = <String>[];

    // Act
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [thaiLanguages],
      home: Scaffold(
        body: ProductStockCard(
          unit: _unit,
          stocks: [_lot('s1', 'L2026A', 10), _lot('s2', 'L2026B', 3)],
          price: ProductPrice(
              id: 'pr1',
              unitId: 'u1',
              productId: 'p1',
              price: 10,
              customerType: 'General'),
          onSequence: () {},
          onAdd: () {},
          onEdit: (_) {},
          onQuantity: (_) {},
          onAdjust: (stock) => adjusted.add(stock.id),
        ),
      ),
    ));
    await tester.tap(find.byTooltip('ปรับสต็อก ล็อต L2026B'));

    // Assert
    expect(find.text('ล็อต'), findsOneWidget);
    expect(find.text('L2026A'), findsOneWidget);
    expect(find.text('L2026B'), findsOneWidget);
    expect(find.text('คงเหลือรวมทั้งหมด: 13 ชิ้น'), findsOneWidget);
    expect(adjusted, ['s2']);
  });

  testWidgets(
      'on a phone the stock row shows it scrolls, and its adjust control can '
      'be scrolled to and pressed', (tester) async {
    // Arrange
    useViewSize(tester, phoneSize);
    final adjusted = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: CustomTheme.mainTheme,
      localizationsDelegates: const [thaiLanguages],
      home: Scaffold(
        body: ProductStockCard(
          unit: _unit,
          stocks: [_lot('s1', 'L2026A', 10)],
          price: ProductPrice(
              id: 'pr1',
              unitId: 'u1',
              productId: 'p1',
              price: 10,
              customerType: 'General'),
          onSequence: () {},
          onAdd: () {},
          onEdit: (_) {},
          onQuantity: (_) {},
          onAdjust: (stock) => adjusted.add(stock.id),
        ),
      ),
    ));
    final adjust = find.byTooltip('ปรับสต็อก ล็อต L2026A');

    // Act
    final offScreen = tester.getRect(adjust).right > phoneSize.width;
    await tester.ensureVisible(adjust);
    await tester.pumpAndSettle();
    await tester.tap(adjust);

    // Assert: the row is wider than the phone and says so with a thumb
    expect(offScreen, isTrue, reason: 'the row overflows a phone');
    final bar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(bar.thumbVisibility, isTrue);
    expect(adjusted, ['s1']);
  });
}
