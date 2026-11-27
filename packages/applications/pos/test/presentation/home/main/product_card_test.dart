import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/home/main/product_card.dart';

import '../../../support/app_fonts.dart';
import '../../../support/selling_products.dart';

ProductUnitItem _item({
  String name = 'พาราเซตามอล 500 มก.',
  int quantity = 48,
  int minStock = 0,
  String category = 'Medicine',
}) =>
    sellingProduct('a',
            name: name,
            quantity: quantity,
            minStock: minStock,
            category: category,
            price: 12)
        .toProductItems()
        .single;

Future<List<int>> _pump(
  WidgetTester tester,
  ProductUnitItem item, {
  int inCart = 0,
  bool compact = false,
  double width = 240,
  double textScale = 1,
}) async {
  final taps = <int>[];
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: compact ? ProductCard.compactHeight : ProductCard.height,
            child: ProductCard(
              item: item,
              inCart: inCart,
              compact: compact,
              onAdd: () => taps.add(1),
            ),
          ),
        ),
      ),
    ),
  ));
  return taps;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the category, name, price, stock left and the add cue',
      (tester) async {
    await _pump(tester, _item());

    expect(find.text('ยารักษาโรค'), findsOneWidget);
    expect(find.text('พาราเซตามอล 500 มก.'), findsOneWidget);
    expect(find.text('฿12.00'), findsOneWidget);
    expect(find.text('คงเหลือ 48 ชิ้น'), findsOneWidget);
    expect(find.text('เพิ่มลงตะกร้า'), findsOneWidget);
    final price = tester.widget<Text>(find.text('฿12.00'));
    expect(price.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()));
  });

  testWidgets('a tap anywhere on the card adds the product', (tester) async {
    final taps = await _pump(tester, _item());

    await tester.tap(find.text('พาราเซตามอล 500 มก.'));
    await tester.tap(find.text('เพิ่มลงตะกร้า'));

    expect(taps, hasLength(2));
  });

  testWidgets('once in the cart the card says how many and is outlined',
      (tester) async {
    await _pump(tester, _item(), inCart: 2);

    expect(find.text('ในตะกร้า 2'), findsOneWidget);
    expect(find.text('เพิ่มลงตะกร้า'), findsNothing);
    expect(tester.widget<AppCard>(find.byType(AppCard)).selected, isTrue);
  });

  testWidgets('out of stock: muted, says so, and a tap still reports',
      (tester) async {
    final taps = await _pump(tester, _item(quantity: 0));

    expect(find.text('สินค้าหมด'), findsOneWidget);
    expect(find.text('หมด'), findsOneWidget);
    expect(tester.widget<AppCard>(find.byType(AppCard)).muted, isTrue);

    await tester.tap(find.byType(ProductCard));
    expect(taps, hasLength(1));
  });

  testWidgets('low stock is marked in the warning tone', (tester) async {
    await _pump(tester, _item(quantity: 3, minStock: 5));

    final left = tester.widget<Text>(find.text('คงเหลือ 3 ชิ้น'));
    expect(left.style?.color, AppColors.light.statusWarningText);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('the card is one button whose name says what a tap does',
      (tester) async {
    await _pump(tester, _item());

    final node = tester.getSemantics(find.byType(ProductCard));
    expect(node.flagsCollection.isButton, isTrue);
    // The name comes first: an end-to-end flow finds the card by a label
    // that begins with it.
    expect(node.label, startsWith('พาราเซตามอล 500 มก.'));
    expect(node.label, contains('ยารักษาโรค'));
    expect(node.label, contains('฿12.00'));
    expect(node.label, contains('เพิ่มลงตะกร้า'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.label, contains('คงเหลือ 48 ชิ้น'));
  });

  for (final compact in [false, true]) {
    testWidgets(
        'a 60-character name at a large text size keeps to two lines and '
        'overflows nothing (compact=$compact)', (tester) async {
      await _pump(
        tester,
        _item(name: 'ยาแก้ปวดลดไข้ชนิดเม็ดเคลือบฟิล์มสำหรับผู้ใหญ่และเด็กอายุมากกว่าสิบสองปีขึ้นไป'),
        compact: compact,
        width: compact ? 160 : 220,
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      final name = tester.renderObject<RenderBox>(find.textContaining('ยาแก้ปวด'));
      final price = tester.getRect(find.text('฿12.00'));
      final card = tester.getRect(find.byType(ProductCard));
      expect(name.size.height, lessThan(70));
      expect(price.bottom, lessThanOrEqualTo(card.bottom));
    });
  }

  testWidgets('compact: a plus instead of the add label', (tester) async {
    await _pump(tester, _item(), compact: true, width: 160);

    expect(find.text('เพิ่มลงตะกร้า'), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('คงเหลือ 48 ชิ้น'), findsOneWidget);
  });
}
