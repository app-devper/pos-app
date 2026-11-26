// The สินค้า list's row: under the product's name, its price and what is on
// hand in each of its units, from the catalogue the list already holds. Low
// or no stock (of the product as a whole, as the list's sort counts it) is
// said in words, in the text colour, after a coloured icon.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/product/main/products_view_model.dart';
import 'package:pos/presentation/product/main/products_widget.dart';
import '../../../support/app_languages.dart';
import '../product_navigation_test.dart' as products;

ProductStock _stock(int quantity, {String unitId = 'u-1'}) => ProductStock(
      id: 's-$unitId',
      unitId: unitId,
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

/// Paracetamol sold as a เม็ด ([tablets] on hand) and as a แผง ([strips] on
/// hand), with a minimum of [minStock].
Product _twoUnits(
    {required int tablets, required int strips, int minStock = 0}) {
  final product = products.paracetamol();
  return Product(
    id: product.id,
    name: product.name,
    status: product.status,
    category: product.category,
    createdDate: product.createdDate,
    minStock: minStock,
    units: [
      ...product.units,
      ProductUnit(
        id: 'u-2',
        productId: product.id,
        costPrice: 40,
        unit: 'แผง',
        size: 10,
        barcode: '222',
        volume: 0,
        volumeUnit: '',
      ),
    ],
    prices: product.prices,
    stocks: [_stock(tablets), _stock(strips, unitId: 'u-2')],
  );
}

Future<void> _showList(WidgetTester tester, Product product,
    {ThemeData? theme}) async {
  sl.registerFactory(
      () => ProductsViewModel(productRepo: products.Catalogue([product])));
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    localizationsDelegates: const [thaiLanguages],
    home: Scaffold(
      body: ProductsWidget(onSelected: (_) {}, onMenu: () {}, onAdd: () {}),
    ),
  ));
  await tester.pumpAndSettle();
}

/// The rich text that reads [text], its icons left out.
Finder _rich(String text) => find.byWidgetPredicate((widget) =>
    widget is RichText &&
    widget.text.toPlainText(includePlaceholders: false) == text);

/// The span of the row's text that reads [text].
TextSpan _span(WidgetTester tester, String text) {
  TextSpan? found;
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == text) found = span;
      return found == null;
    });
  }
  return found ?? (throw StateError('no span reads "$text"'));
}

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

  group('a product in two units', () {
    testWidgets('shows what is on hand in each, and no หมด while one has some',
        (tester) async {
      // Arrange, Act
      await _showList(tester, _twoUnits(tablets: 0, strips: 20));

      // Assert
      expect(_rich('฿10.00 · คงเหลือ 0 เม็ด · 20 แผง'), findsOneWidget);
    });

    testWidgets('says หมด when every unit is empty', (tester) async {
      // Arrange, Act
      await _showList(tester, _twoUnits(tablets: 0, strips: 0));

      // Assert
      expect(_rich('฿10.00 · คงเหลือ 0 เม็ด · 0 แผง · หมด'), findsOneWidget);
    });

    testWidgets('says ใกล้หมด when the total is at its minimum',
        (tester) async {
      // Arrange, Act
      await _showList(tester, _twoUnits(tablets: 2, strips: 3, minStock: 5));

      // Assert
      expect(
          _rich('฿10.00 · คงเหลือ 2 เม็ด · 3 แผง · ใกล้หมด'), findsOneWidget);
    });

    testWidgets('says nothing of a minimum the shop has not set',
        (tester) async {
      // Arrange, Act
      await _showList(tester, _twoUnits(tablets: 1, strips: 0));

      // Assert
      expect(_rich('฿10.00 · คงเหลือ 1 เม็ด · 0 แผง'), findsOneWidget);
    });
  });

  testWidgets('a negative on hand shows its figure and หมด', (tester) async {
    // Arrange, Act
    await _showList(tester, _paracetamol(onHand: -2));

    // Assert
    expect(_rich('฿10.00 · คงเหลือ -2 เม็ด · หมด'), findsOneWidget);
  });

  for (final (name, theme, colors) in [
    ('light', CustomTheme.mainTheme, AppColors.light),
    ('dark', CustomTheme.darkTheme, AppColors.dark),
  ]) {
    group('in the $name theme the cue reads in the text colour', () {
      for (final (cue, onHand, minStock, icon) in [
        ('หมด', 0, 0, Icons.error_outline),
        ('ใกล้หมด', 3, 5, Icons.warning_amber_rounded),
      ]) {
        testWidgets('$cue, after its icon', (tester) async {
          // Arrange, Act
          await _showList(
              tester, _paracetamol(onHand: onHand, minStock: minStock),
              theme: theme);

          // Assert
          final style = _span(tester, cue).style!;
          expect(style.color, colors.textPrimary);
          expect(style.fontWeight, FontWeight.w600);
          final shown = tester.widget<Icon>(find.byIcon(icon));
          expect(shown.size, 16);
        });
      }
    });
  }
}
