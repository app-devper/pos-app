import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/container.dart';
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/home/main/product_search.dart';
import 'package:pos/presentation/home/main/product_search_view_model.dart';

/// Hands out the stock the server holds now: [onHand] is set by the test
/// between loads, the way a sale moves it.
class _StockRepository implements ProductRepository {
  int onHand;
  int loads = 0;

  _StockRepository({required this.onHand});

  @override
  Future<List<Product>> getLocalProducts() async {
    loads++;
    return [_product(onHand)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Product _product(int quantity) => Product(
      id: 'product-1',
      name: 'Paracetamol',
      status: productStatusActive,
      category: 'General',
      createdDate: '',
      units: [
        ProductUnit(
          id: 'unit-1',
          productId: 'product-1',
          costPrice: 5,
          unit: 'ชิ้น',
          size: 1,
          barcode: '111',
          volume: 0,
          volumeUnit: '',
        ),
      ],
      prices: const [],
      stocks: [
        ProductStock(
          id: 'stock-1',
          unitId: 'unit-1',
          productId: 'product-1',
          receiveCode: '',
          sequence: 1,
          lotNumber: 'LOT-1',
          costPrice: 5,
          price: 10,
          import: quantity,
          quantity: quantity,
          expireDate: '',
          importDate: '',
        ),
      ],
    );

void main() {
  group('ProductSearchViewModel.refresh', () {
    test('loads the products again and keeps the search the cashier typed',
        () async {
      // Arrange
      final repo = _StockRepository(onHand: 1000);
      final vm = ProductSearchViewModel(productRepo: repo);
      await vm.prepareData();
      vm.searchProduct('para');
      repo.onHand = 998;

      // Act
      await vm.refresh();

      // Assert
      expect(repo.loads, 2);
      expect(vm.items.value, hasLength(1));
      expect(vm.items.value!.single.getQuantity(), 998);
    });
  });

  group('ProductSearch', () {
    tearDown(() async => sl.reset());

    testWidgets('after a sale the grid shows the stock the server now holds',
        (tester) async {
      // Arrange: 1000 on hand when the screen opens
      final repo = _StockRepository(onHand: 1000);
      sl.registerFactory(() => ProductSearchViewModel(productRepo: repo));
      final sales = StreamController<Object?>.broadcast();
      addTearDown(sales.close);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProductSearch(onSelected: (_) {}, saleRecorded: sales.stream),
        ),
      ));
      await tester.pump();
      expect(find.text('คงเหลือ 1000 ชิ้น'), findsOneWidget);

      // Act: a sale of 2 is recorded
      repo.onHand = 998;
      sales.add(null);
      await tester.pump();
      await tester.pump();

      // Assert
      expect(repo.loads, 2, reason: 'one sale reloads the grid once');
      expect(find.text('คงเหลือ 998 ชิ้น'), findsOneWidget);
    });
  });
}
