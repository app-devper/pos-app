import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/container.dart';
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/order/order.dart';
import 'package:pos/domain/model/order/param.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/model/sale/till.dart';
import 'package:pos/domain/repositories/order_repository.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/domain/usecase/order/checkout_sale_use_case.dart';
import 'package:pos/presentation/home/main/cart_page.dart';
import 'package:pos/presentation/home/main/cart_view_model.dart';
import 'package:pos/presentation/home/main/product_search.dart';
import 'package:pos/presentation/home/main/product_search_view_model.dart';
import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';

const _barcode = '111';

class SaleProducts implements ProductRepository {
  @override
  Future<List<Product>> getLocalProducts() async => [_product()];

  @override
  Future<Product?> getProductByBarcode(String barcode) async =>
      barcode == _barcode ? _product() : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Records every sale as bill [billCode], the code the server gave it.
class SaleOrders implements OrderRepository {
  final String billCode;

  SaleOrders(this.billCode);

  @override
  Future<OrderResult> createOrder(CreateOrderParam param) async => OrderResult(
        data: Order(
          id: 'order-1',
          code: billCode,
          customerCode: '',
          customerName: '',
          createdDate: '2026-11-26T10:00:00Z',
          total: 10,
          totalCost: 5,
          discount: 0,
          type: 'Cash',
        ),
        stocks: const [],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Product _product() => Product(
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
          barcode: _barcode,
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
          import: 1000,
          quantity: 1000,
          expireDate: '',
          importDate: '',
        ),
      ],
    );

/// Registers what the selling screen ([CartPage]) needs: one product, and
/// sales recorded as bill [billCode]. Also used by the layout sweep.
void registerSellingScreen(String billCode) {
  sl.registerFactory(() => ProductSearchViewModel(productRepo: SaleProducts()));
  sl.registerLazySingleton(() => CartViewModel(
        productRepo: SaleProducts(),
        till: Till(),
        checkoutSaleUseCase:
            CheckoutSaleUseCase(orderRepo: SaleOrders(billCode)),
      ));
}

/// The selling screen on a wide window (grid, cart and slots side by side),
/// recording sales as bill [billCode].
Future<void> _openSellingScreen(WidgetTester tester, String billCode) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  registerSellingScreen(billCode);
  await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: [thaiLanguages],
      home: Scaffold(body: CartPage())));
  await _settle(tester);
}

/// Pumps through dialogs and snackbar animations without waiting on the
/// spinners, which never settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder get _searchField => find.descendant(
    of: find.byType(ProductSearch), matching: find.byType(EditableText));

/// Scans [_barcode] into the search field, then pays the exact amount.
Future<void> _sellOne(WidgetTester tester) async {
  await tester.enterText(_searchField, _barcode);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _settle(tester);
  await tester.tap(find.textContaining('ชำระเงิน ('));
  await _settle(tester);
  await tester.tap(find.text('รับชำระพอดี ไม่มีเงินทอน'));
  await _settle(tester);
}

void main() {
  // The app's fonts: an overflow of the cart or its dialogs fails the test.
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  testWidgets('a sale says it is done and names its bill', (tester) async {
    // Arrange
    await _openSellingScreen(tester, 'OD_202611260007');

    // Act
    await _sellOne(tester);

    // Assert
    expect(find.text('ขายสำเร็จ เลขที่บิล OD_202611260007'), findsOneWidget);
  });

  testWidgets('a sale whose bill code is unknown says only that it is done',
      (tester) async {
    // Arrange
    await _openSellingScreen(tester, '');

    // Act
    await _sellOne(tester);

    // Assert
    expect(find.text('ขายสำเร็จ'), findsOneWidget);
  });

  testWidgets('after a sale the next scan goes into the search field',
      (tester) async {
    // Arrange
    await _openSellingScreen(tester, 'OD_202611260007');

    // Act
    await _sellOne(tester);

    // Assert
    final field = tester.widget<EditableText>(_searchField);
    expect(find.text('ชำระเงิน', skipOffstage: false), findsNothing,
        reason: 'the payment dialog has closed');
    expect(FocusManager.instance.primaryFocus, same(field.focusNode));
  }, variant: TargetPlatformVariant.all());
}
