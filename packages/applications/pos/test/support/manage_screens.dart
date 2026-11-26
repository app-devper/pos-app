// The จัดการ screens the widget tests have fakes for (suppliers,
// categories, stock counts), a product's sales history and the lot form:
// the accessibility walk and the layout sweep go through them as well.

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/category/edit/category_edit_page.dart';
import 'package:pos/presentation/category/edit/category_edit_view_model.dart';
import 'package:pos/presentation/category/main/category_page.dart';
import 'package:pos/presentation/category/main/category_view_model.dart';
import 'package:pos/presentation/order/history/order_history_page.dart';
import 'package:pos/presentation/order/history/order_history_view_model.dart';
import 'package:pos/presentation/product/stock/product_stock_widget.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_page.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_view_model.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_manage_page.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_manage_view_model.dart';
import 'package:pos/presentation/supplier/edit/supplier_edit_page.dart';
import 'package:pos/presentation/supplier/edit/supplier_edit_view_model.dart';
import 'package:pos/presentation/supplier/main/suppliers_page.dart';
import 'package:pos/presentation/supplier/main/suppliers_view_model.dart';
import 'main_screens.dart';
import '../presentation/category/edit/category_edit_view_model_test.dart'
    as category_edit;
import '../presentation/category/main/category_view_model_test.dart'
    as categories;
import '../presentation/inventory/product_return_widget_test.dart'
    as product_return;
import '../presentation/order/history/order_history_view_model_test.dart'
    as history;
import '../presentation/product/product_navigation_test.dart' as products;
import '../presentation/stock_count/manage/stock_count_manage_view_model_test.dart'
    as counts;
import '../presentation/supplier/edit/supplier_edit_view_model_test.dart'
    as supplier_edit;
import '../presentation/supplier/main/suppliers_view_model_test.dart'
    as suppliers;

final _unit = ProductUnit(
  id: 'u1',
  productId: 'p-1',
  costPrice: 5,
  unit: 'ชิ้น',
  size: 1,
  barcode: '',
  volume: 0,
  volumeUnit: '',
);

final manageScreens = <String, Screen>{
  'the suppliers list': () {
    sl.registerFactory(() => SuppliersViewModel(
            supplierRepo: suppliers.FakeSupplierRepository(suppliers: [
          suppliers.buildSupplier('1'),
          suppliers.buildSupplier('2'),
        ])));
    return const SuppliersPage();
  },
  'the supplier edit form': () {
    sl.registerFactory(() => SupplierEditViewModel(
        supplierRepo: supplier_edit.FakeSupplierRepository()));
    return SupplierEditPage(supplier: supplier_edit.buildSupplier('1'));
  },
  'the categories list': () {
    sl.registerFactory(() => CategoryViewModel(
            categoryRepo: categories.FakeCategoryRepository(categories: [
          categories.buildCategory('1'),
          categories.buildCategory('2'),
        ])));
    return const CategoryPage();
  },
  'the category edit form': () {
    sl.registerFactory(() => CategoryEditViewModel(
        categoryRepo: category_edit.FakeCategoryRepository()));
    return CategoryEditPage(category: category_edit.buildCategory('1'));
  },
  'the stock counts list': () {
    sl.registerFactory(() => StockCountsViewModel(
        stockCountRepo: counts.FakeStockCountRepository()));
    return const StockCountsPage();
  },
  'a new stock count with a line': () {
    final count = StockCountManageViewModel(
      stockCountRepo: counts.FakeStockCountRepository(),
      productRepo: counts.FakeProductRepository(),
    )..addItem(counts.buildItem());
    sl.registerFactory(() => count);
    return const StockCountManagePage();
  },
  'a stock count': () {
    sl.registerFactory(() => StockCountManageViewModel(
          stockCountRepo: counts.FakeStockCountRepository(),
          productRepo: counts.FakeProductRepository(),
        ));
    return const StockCountManagePage(stockCountId: 'sc1');
  },
  'a product sales history': () {
    sl.registerFactory(() => OrderHistoryViewModel(
        orderRepo: history.FakeOrderRepository(
            items: [history.buildItem('i1'), history.buildItem('i2')])));
    return OrderHistoryPage(product: products.paracetamol());
  },
  'the lot form': () {
    sl.registerFactory<ProductRepository>(() => product_return.Products());
    return Scaffold(
      body: ProductStockWidget(
        unit: _unit,
        price: ProductPrice(
            id: 'pr1',
            unitId: 'u1',
            productId: 'p-1',
            price: 10,
            customerType: 'General'),
        onComplete: (_) {},
      ),
    );
  },
};
