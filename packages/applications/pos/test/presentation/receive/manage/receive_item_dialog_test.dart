// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/model/receive/receive_item.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/receive/manage/receive_item_dialog.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_item_picker_view_model.dart';

class PickerCatalogue implements ProductRepository {
  final List<Product> products;

  PickerCatalogue(this.products);

  @override
  Future<List<Product>> getProducts() async => products;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Product pickerProduct(String id, String name, double cost) => Product(
      id: id,
      name: name,
      price: 10,
      costPrice: cost,
      unit: 'ชิ้น',
      quantity: 0,
      soldFirst: 0,
      serialNumber: '',
      status: productStatusActive,
      category: 'General',
      minStock: 0,
      createdDate: '',
      units: [
        ProductUnit(
          id: 'unit-$id',
          productId: id,
          costPrice: cost,
          unit: 'ชิ้น',
          size: 1,
          barcode: '',
          volume: 0,
          volumeUnit: '',
        ),
      ],
      prices: const [],
      stocks: const [],
    );

/// Opens the dialog for a page that knows [pageProducts], its picker
/// searching [catalogue]; returns what the dialog hands back, once closed.
Future<ReceiveItem? Function()> _openDialog(WidgetTester tester,
    {required List<Product> pageProducts,
    required List<Product> catalogue}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  sl.registerFactory(() =>
      StockCountItemPickerViewModel(productRepo: PickerCatalogue(catalogue)));
  ReceiveItem? added;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            added = await showDialog<ReceiveItem>(
              context: context,
              builder: (_) =>
                  ReceiveItemDialog(receiveId: 'r1', products: pageProducts),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => added;
}

/// Picks [name] in the product picker, found by searching [query].
Future<void> _pick(WidgetTester tester, String query, String name) async {
  await tester.tap(find.widgetWithText(TextFormField, 'สินค้า'));
  await tester.pumpAndSettle();
  await tester.enterText(
      find.widgetWithText(TextField, 'ค้นหาสินค้า...'), query);
  await tester.pump();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

/// Fills the rest of the line and adds it.
Future<void> _completeLine(WidgetTester tester) async {
  await tester.enterText(
      find.widgetWithText(TextFormField, 'จำนวน (ชิ้น)'), '5');
  await tester.enterText(find.widgetWithText(TextFormField, 'เลขล็อต'), 'L1');
  await tester.enterText(
      find.widgetWithText(TextFormField, 'วันหมดอายุ (YYYY-MM-DD)'),
      '2030-01-31');
  await tester.tap(find.text('เพิ่มรายการ'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async => sl.reset());

  testWidgets(
      'a product the picker found but the page had not loaded is still chosen',
      (tester) async {
    // Arrange: the page's list predates the product the picker loads
    final added = await _openDialog(tester, pageProducts: [
      pickerProduct('p1', 'Paracetamol', 5)
    ], catalogue: [
      pickerProduct('p1', 'Paracetamol', 5),
      pickerProduct('p3', 'Cetirizine', 4.25),
    ]);

    // Act
    await _pick(tester, 'ceti', 'Cetirizine');

    // Assert: the field names it and the cost is prefilled
    expect(find.widgetWithText(TextFormField, 'Cetirizine'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '4.25'), findsOneWidget);

    // Act
    await _completeLine(tester);

    // Assert
    expect(added()?.productId, 'p3');
    expect(added()?.product?.name, 'Cetirizine');
    expect(added()?.costPrice, 4.25);
  });

  testWidgets(
      'a receipt line picks its product through the search and the cost '
      'follows', (tester) async {
    // Arrange
    final catalogue = [
      pickerProduct('p1', 'Paracetamol', 5),
      pickerProduct('p2', 'Ibuprofen', 7.5),
    ];
    final added = await _openDialog(tester,
        pageProducts: catalogue, catalogue: catalogue);

    // Act: open the picker from the product field, search, choose
    await _pick(tester, 'ibu', 'Ibuprofen');

    // Assert: the field names it and the cost is prefilled
    expect(find.widgetWithText(TextFormField, 'Ibuprofen'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '7.5'), findsOneWidget);

    // Act: the rest of the line, then add it
    await _completeLine(tester);

    // Assert
    expect(added()?.productId, 'p2');
    expect(added()?.costPrice, 7.5);
    expect(added()?.quantity, 5);
  });
}
