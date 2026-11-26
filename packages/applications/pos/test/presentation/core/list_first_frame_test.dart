// A list does not say ยังไม่มี… (with its add) before its first load has
// answered: until then it is loading.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/category/main/category_page.dart';
import 'package:pos/presentation/category/main/category_view_model.dart';
import 'package:pos/presentation/product/main/product_page.dart';
import 'package:pos/presentation/product/main/product_view_model.dart';
import 'package:pos/presentation/product/main/products_view_model.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_page.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_view_model.dart';
import 'package:pos/presentation/supplier/main/suppliers_page.dart';
import 'package:pos/presentation/supplier/main/suppliers_view_model.dart';
import '../../support/app_languages.dart';
import '../../support/empty_repositories.dart';
import '../category/main/category_view_model_test.dart' as categories;
import '../product/product_navigation_test.dart' as products;
import '../supplier/main/suppliers_view_model_test.dart' as suppliers;

/// Each list, over a repository that holds nothing: once loaded it does
/// say ยังไม่มี…, but not before.
final _lists = <String, Widget Function()>{
  'the categories list': () {
    sl.registerFactory(() =>
        CategoryViewModel(categoryRepo: categories.FakeCategoryRepository()));
    return const CategoryPage();
  },
  'the suppliers list': () {
    sl.registerFactory(() =>
        SuppliersViewModel(supplierRepo: suppliers.FakeSupplierRepository()));
    return const SuppliersPage();
  },
  'the stock counts list': () {
    sl.registerFactory(
        () => StockCountsViewModel(stockCountRepo: NoStockCounts()));
    return const StockCountsPage();
  },
  'the products list': () {
    final catalogue = products.Catalogue([]);
    sl.registerFactory(() => ProductViewModel(productRepo: catalogue));
    sl.registerFactory(() => ProductsViewModel(productRepo: catalogue));
    return const Scaffold(body: ProductsPage());
  },
};

void main() {
  tearDown(() async => sl.reset());

  for (final MapEntry(key: name, value: build) in _lists.entries) {
    testWidgets('$name shows no empty state in its first frame',
        (tester) async {
      // Act: the first frame only
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [thaiLanguages],
        home: build(),
      ));

      // Assert
      expect(find.textContaining('ยังไม่มี'), findsNothing);

      // And once loaded, the empty list says so
      await tester.pumpAndSettle();
      expect(find.textContaining('ยังไม่มี'), findsOneWidget);
    });
  }
}
