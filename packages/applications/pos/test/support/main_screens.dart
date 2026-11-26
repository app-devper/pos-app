// The main screens and dialogs the widget tests already know how to build,
// with their fakes: the layout sweep and the accessibility walk go through
// the same set.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/localizations/localizations_delegate.dart';
import 'package:design_system/theme/theme.dart';
import 'package:design_system/widgets/dialogs.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/customer/add/customer_add_view_model.dart';
import 'package:pos/presentation/customer/edit/customer_edit_page.dart';
import 'package:pos/presentation/customer/edit/customer_edit_view_model.dart';
import 'package:pos/presentation/customer/main/customer_page.dart';
import 'package:pos/presentation/customer/main/customer_view_model.dart';
import 'package:pos/presentation/customer/main/customers_view_model.dart';
import 'package:pos/presentation/home/main/cart_page.dart';
import 'package:pos/presentation/home/main/payment_screen.dart';
import 'package:pos/presentation/order/return/product_return_view_model.dart';
import 'package:pos/presentation/order/return/product_return_widget.dart';
import 'package:pos/presentation/product/edit/product_edit_page.dart';
import 'package:pos/presentation/product/edit/product_edit_view_model.dart';
import 'package:pos/presentation/product/main/product_page.dart';
import 'package:pos/presentation/product/main/product_view_model.dart';
import 'package:pos/presentation/product/main/products_view_model.dart';
import 'package:pos/presentation/product/stock/product_stock_quantity_widget.dart';
import 'package:pos/presentation/receive/manage/receive_item_dialog.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_item_picker_view_model.dart';
import 'app_languages.dart';
import 'empty_repositories.dart';
import '../presentation/customer/edit/customer_edit_page_test.dart'
    as customer_edit;
import '../presentation/customer/main/customer_page_test.dart' as customers;
import '../presentation/home/main/cart_page_sale_test.dart' as cart;
import '../presentation/inventory/product_return_widget_test.dart'
    as product_return;
import '../presentation/product/product_navigation_test.dart' as products;
import '../presentation/receive/manage/receive_item_dialog_test.dart'
    as receive_item;

/// One screen: registers what it needs, then returns the widget to pump.
typedef Screen = Widget Function();

/// A button that opens a dialog, so the dialog is laid out as the app shows
/// it, over a page.
Widget dialogOpener(void Function(BuildContext) open) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    );

ProductStock _stock() => ProductStock(
      id: 's1',
      unitId: 'u-1',
      productId: 'p-1',
      receiveCode: '',
      sequence: 1,
      lotNumber: 'L20261126041051-86725',
      costPrice: 4,
      price: 10,
      import: 10,
      quantity: 10,
      expireDate: '2030-01-31T00:00:00Z',
      importDate: '2026-11-26T00:00:00Z',
    );

void _registerProducts() {
  final catalogue = products.Catalogue([products.paracetamol()]);
  sl.registerFactory(() => ProductViewModel(productRepo: catalogue));
  sl.registerFactory(() => ProductsViewModel(productRepo: catalogue));
  sl.registerFactory(() => ProductEditViewModel(productRepo: catalogue));
}

void _registerCustomers() {
  final repo = customers.ServerCustomers();
  sl.registerFactory(() => CustomersViewModel(customerRepo: repo));
  sl.registerFactory(() => CustomerViewModel(customerRepo: repo));
  sl.registerFactory(() => CustomerAddViewModel(customerRepo: repo));
}

final mainPages = <String, Screen>{
  'the selling screen': () {
    cart.registerSellingScreen('OD_202611260001');
    return const Scaffold(body: CartPage());
  },
  'the customer list': () {
    _registerCustomers();
    return Scaffold(body: CustomerPage(onBack: () {}));
  },
  'the customer edit form': () {
    sl.registerFactory(() => CustomerEditViewModel(
        customerRepo: customer_edit.RecordingCustomers()));
    return Scaffold(
      body: CustomerEditPage(
        customer: customer_edit.wholesaleCustomer,
        onBack: () {},
        onEdit: () {},
        onRemove: () {},
      ),
    );
  },
  'the product list': () {
    _registerProducts();
    return const Scaffold(body: ProductsPage());
  },
  'the product list with no products': () {
    final catalogue = products.Catalogue([]);
    sl.registerFactory(() => ProductViewModel(productRepo: catalogue));
    sl.registerFactory(() => ProductsViewModel(productRepo: catalogue));
    return const Scaffold(body: ProductsPage());
  },
  'the customer list with no customers': () {
    final repo = NoCustomers();
    sl.registerFactory(() => CustomersViewModel(customerRepo: repo));
    sl.registerFactory(() => CustomerViewModel(customerRepo: repo));
    sl.registerFactory(() => CustomerAddViewModel(customerRepo: repo));
    return Scaffold(body: CustomerPage(onBack: () {}));
  },
  'the product edit form': () {
    _registerProducts();
    return Scaffold(
      body: ProductEditPage(
        product: products.paracetamol(),
        onBack: () {},
        onEdit: () {},
        onRemove: () {},
      ),
    );
  },
};

final mainDialogs = <String, Screen>{
  'the payment dialog': () => dialogOpener((context) => showPaymentDialog(
      context,
      amount: 1234.5,
      onCompleted: (_, __) {},
      onError: () {})),
  'the quantity dialog': () => dialogOpener((context) => showInputNumberDialog(
      context,
      title: 'จำนวนสินค้า',
      onCompleted: (_) {})),
  'the stock quantity dialog': () {
    sl.registerFactory<ProductRepository>(() => product_return.Products());
    return dialogOpener((context) =>
        showStockQuantityDialog(context, stock: _stock(), onComplete: (_) {}));
  },
  'the return dialog': () {
    sl.registerFactory(() =>
        ProductReturnViewModel(productReturnRepo: product_return.ReturnRepo()));
    // As the bill detail opens it (order_detail_page.dart).
    return dialogOpener((context) => showCenterDialog(
          minWidth: 360,
          minHeight: 560,
          maxHeight: 560,
          maxWidth: 360,
          context: context,
          builder: (_) => ProductReturnWidget(
            orderId: 'order',
            orderItemId: 'item',
            productName: 'พาราเซตามอล 500 มก.',
            price: 30,
            maxReturnable: 1,
            onComplete: () {},
          ),
        ));
  },
  'the receipt line dialog': () {
    final catalogue = [receive_item.pickerProduct('p1', 'Paracetamol', 5)];
    sl.registerFactory(() => StockCountItemPickerViewModel(
        productRepo: receive_item.PickerCatalogue(catalogue)));
    return dialogOpener((context) => showDialog<void>(
          context: context,
          builder: (_) =>
              ReceiveItemDialog(receiveId: 'r1', products: catalogue),
        ));
  },
};

/// Pumps [screen] in the app's theme and [languages], opening it when it is
/// a dialog, and lets its loads and animations run for a second.
Future<void> showScreen(WidgetTester tester, Widget screen,
    {required bool isDialog,
    LocalizationsDelegate<Languages> languages = englishLanguages}) async {
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: [
      CommonLocalizationsDelegate(),
      languages,
    ],
    home: screen,
  ));
  if (isDialog) await tester.tap(find.text('open'));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
