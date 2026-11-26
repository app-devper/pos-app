// The สินค้า list's row: under the product's name, its price and what is on
// hand, from the catalogue the list already holds. Low or no stock is said in
// words beside the colour.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/product/main/products_view_model.dart';
import 'package:pos/presentation/product/main/products_widget.dart';
import '../../../support/app_languages.dart';
import '../product_navigation_test.dart' as products;

ProductStock _stock(int quantity) => ProductStock(
      id: 's1',
      unitId: 'u-1',
      productId: 'p-1',
      receiveCode: '',
      sequence: 1,
      lotNumber: 'L1',
      costPrice: 4,
      price: 0,
      import: quantity,
      quantity: quantity,
      expireDate: '',
      importDate: '',
    );

/// Paracetamol at ฿10 a เม็ด, with [onHand] on hand and a minimum of
/// [minStock].
Product _paracetamol({required int onHand, int minStock = 0}) {
  final product = products.paracetamol();
  return Product(
    id: product.id,
    name: product.name,
    status: product.status,
    category: product.category,
    createdDate: product.createdDate,
    minStock: minStock,
    units: product.units,
    prices: product.prices,
    stocks: [_stock(onHand)],
  );
}

Future<void> _showList(WidgetTester tester, Product product) async {
  sl.registerFactory(
      () => ProductsViewModel(productRepo: products.Catalogue([product])));
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [thaiLanguages],
    home: Scaffold(
      body: ProductsWidget(onSelected: (_) {}, onMenu: () {}, onAdd: () {}),
    ),
  ));
  await tester.pumpAndSettle();
}

Finder _rich(String text) => find.text(text, findRichText: true);

void main() {
  tearDown(() async => sl.reset());

  testWidgets('a product row shows its price and what is on hand',
      (tester) async {
    // Arrange, Act
    await _showList(tester, _paracetamol(onHand: 12));

    // Assert
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(_rich('฿10.00 · คงเหลือ 12 เม็ด'), findsOneWidget);
  });

  testWidgets('a product with nothing on hand says หมด, not colour alone',
      (tester) async {
    // Arrange, Act
    await _showList(tester, _paracetamol(onHand: 0));

    // Assert
    expect(_rich('฿10.00 · คงเหลือ 0 เม็ด · หมด'), findsOneWidget);
  });

  testWidgets('a product at or below its minimum says ใกล้หมด', (tester) async {
    // Arrange, Act
    await _showList(tester, _paracetamol(onHand: 3, minStock: 5));

    // Assert
    expect(_rich('฿10.00 · คงเหลือ 3 เม็ด · ใกล้หมด'), findsOneWidget);
  });

  testWidgets('a product with no unit shows its price only', (tester) async {
    // Arrange
    final product = Product(
      id: 'p-2',
      name: 'Gift card',
      price: 50,
      status: 'Active',
      category: 'General',
      createdDate: '',
      units: const [],
      prices: const [],
      stocks: const [],
    );

    // Act
    await _showList(tester, product);

    // Assert
    expect(_rich('฿50.00'), findsOneWidget);
  });
}
