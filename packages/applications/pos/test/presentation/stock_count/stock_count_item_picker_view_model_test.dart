import 'dart:async';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_item_picker_view_model.dart';

class _Catalogue implements ProductRepository {
  Future<void> answer = Future.value();

  @override
  Future<List<Product>> getProducts() async {
    await answer;
    return _products;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

List<Product> get _products => [
      Product(
        id: 'p1',
        name: 'Paracetamol',
        unit: 'ชิ้น',
        status: productStatusActive,
        category: 'General',
        createdDate: '',
        units: [_unit('box', 'กล่อง'), _unit('piece', 'ชิ้น')],
        prices: const [],
        stocks: const [],
      ),
      Product(
        id: 'p2',
        name: 'Ibuprofen',
        unit: 'ชิ้น',
        status: productStatusActive,
        category: 'General',
        createdDate: '',
        units: [_unit('piece2', 'ชิ้น')],
        prices: const [],
        stocks: const [],
      ),
    ];

ProductUnit _unit(String id, String name) => ProductUnit(
      id: id,
      productId: 'p1',
      costPrice: 1,
      unit: name,
      size: 1,
      barcode: '',
      volume: 0,
      volumeUnit: '',
    );

void main() {
  test('a stock count lists a product once per unit', () async {
    // Arrange
    final vm = StockCountItemPickerViewModel(productRepo: _Catalogue());

    // Act
    await vm.getProducts();

    // Assert
    expect(vm.state.value.products.map((p) => p.unit.unit),
        ['กล่อง', 'ชิ้น', 'ชิ้น']);
  });

  test('a receipt line lists a product once, in its base unit', () async {
    // Arrange
    final vm = StockCountItemPickerViewModel(productRepo: _Catalogue());

    // Act
    await vm.getProducts(onePerProduct: true);

    // Assert
    expect(vm.state.value.products.map((p) => p.unit.unit), ['ชิ้น', 'ชิ้น']);
  });

  test('a search typed while the products load is kept', () async {
    // Arrange
    final repo = _Catalogue();
    final gate = Completer<void>();
    repo.answer = gate.future;
    final vm = StockCountItemPickerViewModel(productRepo: repo);
    final load = vm.getProducts();

    // Act
    vm.searchProduct('ibu');
    gate.complete();
    await load;

    // Assert
    expect(vm.state.value.products.map((p) => p.name), ['Ibuprofen']);
  });
}
