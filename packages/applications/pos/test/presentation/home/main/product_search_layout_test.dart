// The selling screen's product panel: search, category pills, catalogue
// figures and the grid of cards, on a wide panel and a phone's.

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/container.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/home/main/product_card.dart';
import 'package:pos/presentation/home/main/product_search.dart';
import 'package:pos/presentation/home/main/product_search_view_model.dart';

import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';
import '../../../support/selling_products.dart';

class _Repository implements ProductRepository {
  final List<Product> products;
  _Repository(this.products);

  @override
  Future<List<Product>> getLocalProducts() async => products;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _catalogue = [
  sellingProduct('a', name: 'Paracetamol', category: 'Medicine', quantity: 48),
  sellingProduct('b',
      name: 'Vitamin C', category: 'DietarySupplement', quantity: 21),
  sellingProduct('c',
      name: 'Amoxicillin', category: 'Medicine', quantity: 3, minStock: 5),
  sellingProduct('d', name: 'Plaster', category: 'General', quantity: 0),
];

const _wide = Size(1000, 800);
const _phone = Size(390, 844);

Future<List<String>> _pump(
  WidgetTester tester,
  Size size, {
  List<Product>? products,
  Map<String, int> inCart = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  sl.registerFactory(() => ProductSearchViewModel(
      productRepo: _Repository(products ?? _catalogue)));
  final selected = <String>[];
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: const [thaiLanguages],
    home: Scaffold(
      body: ProductSearch(onSelected: selected.add, inCart: inCart),
    ),
  ));
  await tester.pump();
  return selected;
}

List<String> _cardNames(WidgetTester tester) => [
      for (final card in tester.widgetList<ProductCard>(find.byType(ProductCard)))
        card.item.name,
    ];

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  testWidgets('wide: pills for every category, three figures, full cards',
      (tester) async {
    await _pump(tester, _wide);

    expect(find.text('ทั้งหมด'), findsOneWidget);
    expect(find.text('ยารักษาโรค'), findsWidgets);
    expect(find.text('ผลิตภัณฑ์เสริมอาหาร'), findsWidgets);
    final figures = tester.widgetList<FigureTile>(find.byType(FigureTile));
    expect([for (final f in figures) '${f.label} ${f.value}'],
        ['สินค้า 4', 'สต็อกรวม 72', 'ใกล้หมด 1']);
    expect(figures.last.tone, AppTagTone.warning);
    expect(tester.widget<ProductCard>(find.byType(ProductCard).first).compact,
        isFalse);
    expect(_cardNames(tester), hasLength(4));
  });

  testWidgets('with nothing low the low-stock figure is plain', (tester) async {
    await _pump(tester, _wide,
        products: [sellingProduct('a', quantity: 9, minStock: 2)]);

    final low = tester.widgetList<FigureTile>(find.byType(FigureTile)).last;
    expect(low.value, '0');
    expect(low.tone, AppTagTone.neutral);
  });

  testWidgets('phone: no figures, pills on one scrolling row, two compact '
      'cards per row', (tester) async {
    await _pump(tester, _phone);

    expect(find.byType(FigureTile), findsNothing);
    expect(tester.widget<FilterPills<String?>>(find.byType(FilterPills<String?>))
        .scrollable, isTrue);
    final first = tester.getRect(find.byType(ProductCard).at(0));
    final second = tester.getRect(find.byType(ProductCard).at(1));
    final third = tester.getRect(find.byType(ProductCard).at(2));
    expect(second.top, first.top);
    expect(third.top, greaterThan(first.top));
    expect(tester.widget<ProductCard>(find.byType(ProductCard).first).compact,
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a category pill narrows the grid; ทั้งหมด shows all again',
      (tester) async {
    await _pump(tester, _wide);

    await tester.tap(find.widgetWithText(InkWell, 'ยารักษาโรค').first);
    await tester.pump();
    expect(_cardNames(tester), ['Paracetamol', 'Amoxicillin']);

    await tester.enterText(find.byType(TextField), 'amox');
    await tester.pump();
    expect(_cardNames(tester), ['Amoxicillin']);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('ทั้งหมด'));
    await tester.pump();
    expect(_cardNames(tester), hasLength(4));
  });

  testWidgets('a card says how many of it the open cart holds', (tester) async {
    await _pump(tester, _wide, inCart: const {'bar-b': 2});

    expect(find.text('ในตะกร้า 2'), findsOneWidget);
    final cards = tester.widgetList<ProductCard>(find.byType(ProductCard));
    expect([for (final c in cards) c.inCart], [0, 2, 0, 0]);
  });

  testWidgets('a tap on a card selects its barcode and leaves the cursor in '
      'the search field, ready for a scan', (tester) async {
    final selected = await _pump(tester, _wide);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);

    await tester.tap(find.text('Vitamin C'));
    await tester.pump();

    expect(selected, ['bar-b']);
    expect(field.focusNode!.hasFocus, isTrue);

    // A scan types the code and presses Enter.
    await tester.enterText(find.byType(TextField), 'bar-a');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(selected, ['bar-b', 'bar-a']);
  });

  // On the web and a desktop a tap outside a text field takes its focus;
  // a scan after it would type into nothing.
  testWidgets('on a desktop, a pill or a card tap leaves the cursor in the '
      'search field', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await _pump(tester, _wide);
    final field = tester.widget<TextField>(find.byType(TextField));

    await tester.tap(find.widgetWithText(InkWell, 'ยารักษาโรค').first);
    await tester.pump();
    final afterPill = field.focusNode!.hasFocus;
    await tester.tap(find.text('Paracetamol'));
    await tester.pump();
    final afterCard = field.focusNode!.hasFocus;
    debugDefaultTargetPlatformOverride = null;

    expect(afterPill, isTrue);
    expect(afterCard, isTrue);
  });

  testWidgets('3,000 products build only the cards in view', (tester) async {
    await _pump(tester, _wide, products: [
      for (var i = 0; i < 3000; i++) sellingProduct('$i', quantity: 1),
    ]);

    expect(find.byType(ProductCard).evaluate().length, lessThan(60));
    final figures = tester.widgetList<FigureTile>(find.byType(FigureTile));
    expect(figures.first.value, '3,000');
  });
}
