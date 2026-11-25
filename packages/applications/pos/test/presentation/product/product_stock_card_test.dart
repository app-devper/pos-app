// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/product/main/product_stock_card.dart';

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
  testWidgets('the stock tab shows each lot\'s number', (tester) async {
    // Arrange
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final adjusted = <String>[];

    // Act
    await tester.pumpWidget(MaterialApp(
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
    await tester.tap(find.byTooltip('ปรับสต็อก').last);

    // Assert
    expect(find.text('ล็อต'), findsOneWidget);
    expect(find.text('L2026A'), findsOneWidget);
    expect(find.text('L2026B'), findsOneWidget);
    expect(find.text('คงเหลือรวมทั้งหมด: 13 ชิ้น'), findsOneWidget);
    expect(adjusted, ['s2']);
  });
}
