// On a wide screen a list page puts its list beside a pane. With nothing
// chosen the pane says what to do, rather than standing blank, and offers the
// page's add.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/customer/add/customer_add_view_model.dart';
import 'package:pos/presentation/customer/main/customer_page.dart';
import 'package:pos/presentation/customer/main/customer_view_model.dart';
import 'package:pos/presentation/customer/main/customers_view_model.dart';
import 'package:pos/presentation/product/main/product_page.dart';
import 'package:pos/presentation/product/main/product_view_model.dart';
import 'package:pos/presentation/product/main/products_view_model.dart';
import 'package:pos/presentation/receive/main/receive_page.dart';
import 'package:pos/presentation/receive/main/receives_view_model.dart';
import '../support/app_fonts.dart';
import '../support/app_languages.dart';
import 'customer/main/customer_page_test.dart' as customers;
import 'product/product_navigation_test.dart' as products;
import 'receive/main/receives_view_model_test.dart' as receipts;

Future<void> _showWide(WidgetTester tester, Widget page) async {
  useViewSize(tester, desktopSize);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [thaiLanguages],
    home: page,
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

  testWidgets('the receipts pane asks for a receipt and offers to add one',
      (tester) async {
    // Arrange
    sl.registerFactory(() => ReceivesViewModel(
        receiveRepo: receipts.FakeReceiveRepository(
            receives: [receipts.buildReceive('1', 'RC-1')])));

    // Act
    await _showWide(tester, const ReceivePage());

    // Assert
    expect(find.text('เลือกใบรับสินค้าเพื่อดูรายละเอียด'), findsOneWidget);
    expect(_button('เพิ่มใบรับสินค้า'), findsOneWidget);
  });

  testWidgets('the customers pane asks for a customer and offers to add one',
      (tester) async {
    // Arrange
    final repo = customers.ServerCustomers();
    sl.registerFactory(() => CustomersViewModel(customerRepo: repo));
    sl.registerFactory(() => CustomerViewModel(customerRepo: repo));
    sl.registerFactory(() => CustomerAddViewModel(customerRepo: repo));

    // Act
    await _showWide(tester, Scaffold(body: CustomerPage(onBack: () {})));

    // Assert
    expect(find.text('เลือกลูกค้าเพื่อดูรายละเอียด'), findsOneWidget);
    expect(_button('เพิ่มลูกค้า'), findsOneWidget);
  });

  testWidgets('the products pane asks for a product under its menu',
      (tester) async {
    // Arrange
    final catalogue = products.Catalogue([products.paracetamol()]);
    sl.registerFactory(() => ProductViewModel(productRepo: catalogue));
    sl.registerFactory(() => ProductsViewModel(productRepo: catalogue));

    // Act
    await _showWide(tester, const Scaffold(body: ProductsPage()));

    // Assert
    expect(find.text('เลือกสินค้าเพื่อดูรายละเอียด'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'เพิ่มสินค้า'), findsOneWidget);
  });
}
