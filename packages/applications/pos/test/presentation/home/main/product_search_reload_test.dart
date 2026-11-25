import 'dart:async';

import 'package:common/core/error/exception.dart';
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

/// Each load waits on its own [Completer], so a test decides when, and in
/// which order, the loads come back, and whether one fails.
class _ScriptedRepository implements ProductRepository {
  final pending = <Completer<List<Product>>>[];

  @override
  Future<List<Product>> getLocalProducts() {
    final load = Completer<List<Product>>();
    pending.add(load);
    return load.future;
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

  group('ProductSearchViewModel loads', () {
    test('a failed reload after a sale keeps the grid and shows no error',
        () async {
      // Arrange: the grid loaded 1000 on hand
      final repo = _ScriptedRepository();
      final vm = ProductSearchViewModel(productRepo: repo);
      final first = vm.prepareData();
      repo.pending.single.complete([_product(1000)]);
      await first;
      final shown = vm.items.value;

      // Act: the reload after a sale fails (the network blinked)
      final reload = vm.refresh();
      repo.pending.last
          .completeError(const NetworkException(message: 'offline'));
      await reload;

      // Assert
      expect(vm.items.value, same(shown));
      expect(vm.error.value, isNull,
          reason: 'the cashier keeps selling from the grid they had');
    });

    test('a first load that fails still shows the error', () async {
      // Arrange
      final repo = _ScriptedRepository();
      final vm = ProductSearchViewModel(productRepo: repo);

      // Act
      final first = vm.prepareData();
      repo.pending.single
          .completeError(const NetworkException(message: 'offline'));
      await first;

      // Assert
      expect(vm.error.value, isNotNull);
    });

    test('the load that started last wins, whichever finishes last', () async {
      // Arrange: loaded at 1000, then two quick sales reload twice
      final repo = _ScriptedRepository();
      final vm = ProductSearchViewModel(productRepo: repo);
      final first = vm.prepareData();
      repo.pending.single.complete([_product(1000)]);
      await first;
      final older = vm.refresh();
      final newer = vm.refresh();

      // Act: the newer load (998) comes back before the older one (999)
      repo.pending[2].complete([_product(998)]);
      await newer;
      repo.pending[1].complete([_product(999)]);
      await older;

      // Assert
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
