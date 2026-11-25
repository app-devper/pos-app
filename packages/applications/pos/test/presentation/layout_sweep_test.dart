// The layout sweep: every main screen and dialog the widget tests already
// know how to build, laid out in the app's fonts and theme on a phone
// (360×640) and a desktop (1400×900). Any overflow, or any other error the
// framework reports, fails that screen's test.
//
// It reuses the other tests' fakes; a screen with none is not here (see the
// layout section of docs/e2e-findings.md for what that leaves out).

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/localizations/localizations_delegate.dart';
import 'package:design_system/theme/theme.dart';
import 'package:design_system/widgets/dialogs.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
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
import '../support/app_fonts.dart';
import 'customer/edit/customer_edit_page_test.dart' as customer_edit;
import 'customer/main/customer_page_test.dart' as customers;
import 'home/main/cart_page_sale_test.dart' as cart;
import 'inventory/product_return_widget_test.dart' as product_return;
import 'product/product_navigation_test.dart' as products;
import 'receive/manage/receive_item_dialog_test.dart' as receive_item;

/// One screen: registers what it needs, then returns the widget to pump.
typedef _Screen = Widget Function();

/// A button that opens a dialog, so the dialog is laid out as the app shows
/// it, over a page.
Widget _opener(void Function(BuildContext) open) => Scaffold(
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

final _pages = <String, _Screen>{
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

final _dialogs = <String, _Screen>{
  'the payment dialog': () => _opener((context) => showPaymentDialog(context,
      amount: 1234.5, onCompleted: (_, __) {}, onError: () {})),
  'the quantity dialog': () => _opener((context) => showInputNumberDialog(
      context,
      title: 'จำนวนสินค้า',
      onCompleted: (_) {})),
  'the stock quantity dialog': () {
    sl.registerFactory<ProductRepository>(() => product_return.Products());
    return _opener((context) =>
        showStockQuantityDialog(context, stock: _stock(), onComplete: (_) {}));
  },
  'the return dialog': () {
    sl.registerFactory(() =>
        ProductReturnViewModel(productReturnRepo: product_return.ReturnRepo()));
    return _opener((context) => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            child: SizedBox(
              width: 400,
              height: 550,
              child: ProductReturnWidget(
                orderId: 'order',
                orderItemId: 'item',
                productName: 'พาราเซตามอล 500 มก.',
                price: 30,
                maxReturnable: 1,
                onComplete: () {},
              ),
            ),
          ),
        ));
  },
  'the receipt line dialog': () {
    final catalogue = [receive_item.pickerProduct('p1', 'Paracetamol', 5)];
    sl.registerFactory(() => StockCountItemPickerViewModel(
        productRepo: receive_item.PickerCatalogue(catalogue)));
    return _opener((context) => showDialog<void>(
          context: context,
          builder: (_) =>
              ReceiveItemDialog(receiveId: 'r1', products: catalogue),
        ));
  },
};

/// Pumps [screen] in the app's theme, opening it when it is a dialog, and
/// lets its loads and animations run for a second.
Future<void> _show(WidgetTester tester, Widget screen,
    {required bool isDialog}) async {
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: [
      CommonLocalizationsDelegate(),
      const customers.EnglishLanguages(),
    ],
    home: screen,
  ));
  if (isDialog) await tester.tap(find.text('open'));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  for (final size in [phoneSize, desktopSize]) {
    for (final (screens, isDialog) in [(_pages, false), (_dialogs, true)]) {
      for (final MapEntry(key: name, value: build) in screens.entries) {
        testWidgets('$name lays out without overflow at $size', (tester) async {
          // Arrange
          useViewSize(tester, size);

          // Act
          await _show(tester, build(), isDialog: isDialog);

          // Assert
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
