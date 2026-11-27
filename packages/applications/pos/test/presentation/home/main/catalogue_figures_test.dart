import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/home/main/catalogue_figures.dart';
import 'package:pos/presentation/home/main/product_search_view_model.dart';

import '../../../support/selling_products.dart';

class _Repository implements ProductRepository {
  final List<Product> products;
  _Repository(this.products);

  @override
  Future<List<Product>> getLocalProducts() async => products;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('CatalogueFigures.of', () {
    test('an empty catalogue counts nothing', () {
      final figures = CatalogueFigures.of(const []);

      expect(figures.products, 0);
      expect(figures.totalStock, 0);
      expect(figures.lowStock, 0);
    });

    test('counts products, their stock, and the ones at or under minStock',
        () {
      final figures = CatalogueFigures.of(unitItems([
        sellingProduct('a', quantity: 48),
        sellingProduct('b', quantity: 3, minStock: 5),
        sellingProduct('c', quantity: 5, minStock: 5),
        sellingProduct('d', quantity: 6, minStock: 5),
      ]));

      expect(figures.products, 4);
      expect(figures.totalStock, 62);
      expect(figures.lowStock, 2);
    });

    test('a product with no minStock, or with none left, is not low', () {
      final figures = CatalogueFigures.of(unitItems([
        sellingProduct('a', quantity: 1, minStock: 0),
        sellingProduct('b', quantity: 0, minStock: 5),
        sellingProduct('c', quantity: -2, minStock: 5),
      ]));

      expect(figures.lowStock, 0);
      // An oversold lot does not take stock away from the others.
      expect(figures.totalStock, 1);
    });

    // The สินค้า list decides low on the product's total over its units;
    // the selling screen must say the same.
    test('low is the product as a whole, not one of its units', () {
      final plenty = CatalogueFigures.of(unitItems([
        twoUnitProduct('a', pieces: 100, boxes: 3, minStock: 10),
      ]));
      final low = CatalogueFigures.of(unitItems([
        twoUnitProduct('b', pieces: 5, boxes: 2, minStock: 10),
      ]));

      expect(plenty.lowStock, 0);
      expect(plenty.products, 1);
      expect(plenty.totalStock, 103);
      expect(low.lowStock, 1);
      for (final item in unitItems([
        twoUnitProduct('b', pieces: 5, boxes: 2, minStock: 10),
      ])) {
        expect(item.isLowStock, isTrue);
      }
    });

    test('a product of two units is one product', () {
      final twoUnits = sellingProduct('a', quantity: 4);
      final item = twoUnits.toProductItems().single;

      final figures = CatalogueFigures.of([item, item]);

      expect(figures.products, 1);
    });
  });

  group('ProductSearchViewModel categories and figures', () {
    final products = [
      sellingProduct('a', name: 'Paracetamol', category: 'Medicine'),
      sellingProduct('b', name: 'Vitamin C', category: 'DietarySupplement'),
      sellingProduct('c', name: 'Paraffin', category: 'General', quantity: 2,
          minStock: 3),
    ];

    test('lists the categories the catalogue holds, in the app\'s order',
        () async {
      final vm = ProductSearchViewModel(productRepo: _Repository(products));
      await vm.prepareData();

      // ยารักษาโรค, ผลิตภัณฑ์เสริมอาหาร, สินค้าอื่นๆ
      expect(vm.categories.value, ['Medicine', 'DietarySupplement', 'General']);
      expect(vm.selectedCategory.value, isNull);
    });

    test('a chosen category filters the grid, together with the search',
        () async {
      final vm = ProductSearchViewModel(productRepo: _Repository(products));
      await vm.prepareData();

      vm.selectCategory('Medicine');
      expect([for (final i in vm.items.value!) i.name], ['Paracetamol']);

      vm.selectCategory(null);
      vm.searchProduct('para');
      expect([for (final i in vm.items.value!) i.name],
          ['Paracetamol', 'Paraffin']);

      vm.selectCategory('General');
      expect([for (final i in vm.items.value!) i.name], ['Paraffin']);
    });

    test('the figures are of the whole catalogue, and are worked out once '
        'per load, not per search', () async {
      final vm = ProductSearchViewModel(
          productRepo: _Repository([
        for (var i = 0; i < 3000; i++) sellingProduct('$i', quantity: 1),
      ]));
      await vm.prepareData();
      final figures = vm.figures.value;
      expect(figures.products, 3000);

      vm.searchProduct('สินค้า 12');
      vm.selectCategory('General');

      expect(identical(vm.figures.value, figures), isTrue);
    });

    test('a chosen category that a reload no longer holds is let go',
        () async {
      final repo = _Repository(List.of(products));
      final vm = ProductSearchViewModel(productRepo: repo);
      await vm.prepareData();
      vm.selectCategory('Medicine');
      repo.products.removeWhere((p) => p.category == 'Medicine');

      await vm.refresh();

      expect(vm.selectedCategory.value, isNull);
      expect(vm.items.value, hasLength(2));
    });

    test('codes that read as the same category are one pill and one filter',
        () async {
      final vm = ProductSearchViewModel(
          productRepo: _Repository([
        sellingProduct('a', category: 'Medicine'),
        sellingProduct('b', category: 'medicine'),
        sellingProduct('c', category: 'None'),
        sellingProduct('d', category: ''),
        sellingProduct('e', category: 'Zzz'),
      ]));
      await vm.prepareData();

      // ไม่ระบุประเภท (None and every unknown code), ยารักษาโรค
      expect(vm.categories.value, ['None', 'Medicine']);

      vm.selectCategory('Medicine');
      expect(vm.items.value, hasLength(2));
      vm.selectCategory('None');
      expect(vm.items.value, hasLength(3));
    });

    test('a reload keeps the chosen category', () async {
      final vm = ProductSearchViewModel(productRepo: _Repository(products));
      await vm.prepareData();
      vm.selectCategory('Medicine');

      await vm.refresh();

      expect(vm.selectedCategory.value, 'Medicine');
      expect(vm.items.value, hasLength(1));
    });
  });
}
