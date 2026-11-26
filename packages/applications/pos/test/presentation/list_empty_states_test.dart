// A list with nothing in it says so and offers to add the first one, rather
// than leaving a blank area. A search that finds nothing says that instead,
// with no add.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/category/main/category_page.dart';
import 'package:pos/presentation/category/main/category_view_model.dart';
import 'package:pos/presentation/customer/main/customers_view_model.dart';
import 'package:pos/presentation/customer/main/customers_widget.dart';
import 'package:pos/presentation/product/main/products_view_model.dart';
import 'package:pos/presentation/product/main/products_widget.dart';
import 'package:pos/presentation/receive/main/receives_view_model.dart';
import 'package:pos/presentation/receive/main/receives_widget.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_page.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_view_model.dart';
import 'package:pos/presentation/supplier/main/suppliers_page.dart';
import 'package:pos/presentation/supplier/main/suppliers_view_model.dart';
import '../support/app_fonts.dart';
import '../support/app_languages.dart';
import '../support/empty_repositories.dart';
import 'category/main/category_view_model_test.dart' as categories;
import 'product/product_navigation_test.dart' as products;
import 'receive/main/receives_view_model_test.dart' as receipts;
import 'supplier/main/suppliers_view_model_test.dart' as suppliers;

Future<void> _show(WidgetTester tester, Widget screen) async {
  useViewSize(tester, phoneSize);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [thaiLanguages],
    home: screen,
  ));
  await tester.pumpAndSettle();
}

/// A filled button reading [label] (FilledButton.icon is a subtype).
Finder _button(String label) => find
    .ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is FilledButton))
    .hitTestable();

void main() {
  tearDown(() async => sl.reset());

  testWidgets('an empty product list offers to add the first product',
      (tester) async {
    // Arrange
    var adds = 0;
    sl.registerFactory(
        () => ProductsViewModel(productRepo: products.Catalogue([])));
    await _show(
        tester,
        Scaffold(
            body: ProductsWidget(
                onSelected: (_) {}, onMenu: () {}, onAdd: () => adds++)));

    // Act
    await tester.tap(_button('เพิ่มสินค้ารายการแรก'));

    // Assert
    expect(find.text('ยังไม่มีสินค้า'), findsOneWidget);
    expect(adds, 1);
  });

  testWidgets('a product search that finds nothing says so, with no add',
      (tester) async {
    // Arrange
    sl.registerFactory(() => ProductsViewModel(
        productRepo: products.Catalogue([products.paracetamol()])));
    await _show(
        tester,
        Scaffold(
            body: ProductsWidget(
                onSelected: (_) {}, onMenu: () {}, onAdd: () {})));

    // Act
    await tester.enterText(find.byType(TextField), 'ไม่มีชื่อนี้');
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('ไม่พบรายการที่ค้นหา'), findsOneWidget);
    expect(find.text('เพิ่มสินค้ารายการแรก'), findsNothing);
  });

  testWidgets('an empty receipt list offers to add the first receipt',
      (tester) async {
    // Arrange
    var adds = 0;
    sl.registerFactory(() => ReceivesViewModel(
        receiveRepo: receipts.FakeReceiveRepository(receives: [])));
    await _show(
        tester,
        Scaffold(
            body: ReceivesWidget(
                onSelected: (_) {}, onMenu: () {}, onAdd: () => adds++)));

    // Act
    await tester.tap(_button('เพิ่มใบรับสินค้าใบแรก'));

    // Assert
    expect(find.text('ยังไม่มีใบรับสินค้า'), findsOneWidget);
    expect(adds, 1);
  });

  testWidgets('an empty customer list offers to add the first customer',
      (tester) async {
    // Arrange
    var adds = 0;
    final customers = CustomersViewModel(customerRepo: NoCustomers());
    addTearDown(customers.dispose);
    await _show(
        tester,
        Scaffold(
            body: CustomersWidget(
                viewModel: customers,
                onSelected: (_) {},
                onBack: () {},
                onAdd: () => adds++)));

    // Act
    await tester.tap(_button('เพิ่มลูกค้าคนแรก'));

    // Assert
    expect(find.text('ยังไม่มีลูกค้า'), findsOneWidget);
    expect(adds, 1);
  });

  testWidgets('an empty stock count list offers to start the first count',
      (tester) async {
    // Arrange
    sl.registerFactory(
        () => StockCountsViewModel(stockCountRepo: NoStockCounts()));

    // Act
    await _show(tester, const StockCountsPage());

    // Assert
    expect(find.text('ยังไม่มีการนับสต็อก'), findsOneWidget);
    expect(_button('เริ่มนับสต็อกครั้งแรก'), findsOneWidget);
  });

  testWidgets('an empty category list offers to add the first category',
      (tester) async {
    // Arrange
    sl.registerFactory(() => CategoryViewModel(
        categoryRepo: categories.FakeCategoryRepository(categories: [])));

    // Act
    await _show(tester, const CategoryPage());

    // Assert
    expect(find.text('ยังไม่มีหมวดหมู่'), findsOneWidget);
    expect(_button('เพิ่มหมวดหมู่แรก'), findsOneWidget);
  });

  testWidgets('an empty supplier list offers to add the first supplier',
      (tester) async {
    // Arrange
    sl.registerFactory(() => SuppliersViewModel(
        supplierRepo: suppliers.FakeSupplierRepository(suppliers: [])));

    // Act
    await _show(tester, const SuppliersPage());

    // Assert
    expect(find.text('ยังไม่มีร้านขายสินค้า'), findsOneWidget);
    expect(_button('เพิ่มร้านขายสินค้าร้านแรก'), findsOneWidget);
  });
}
