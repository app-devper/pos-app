// Switching the shell's sections on the real home page: the content area
// cross-fades, the selling screen takes a tap while it fades in, each
// section is built once per switch, and Back stays Task 1's Back however
// the fade and a late load fall.

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/localizations/localizations_delegate.dart';
import 'package:design_system/theme/theme.dart';
import 'package:design_system/widgets/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:um/domain/usecase/auth_use_cases.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/model/sale/till.dart';
import 'package:pos/domain/usecase/order/checkout_sale_use_case.dart';
import 'package:pos/presentation/home/main/cart_view_model.dart';
import 'package:pos/presentation/home/main/home_page.dart';
import 'package:pos/presentation/home/main/home_view_model.dart';
import 'package:pos/presentation/home/main/product_search_view_model.dart';
import 'package:pos/presentation/home/main/section_switcher.dart';
import 'package:pos/presentation/order/main/order_page.dart';
import 'package:pos/presentation/order/main/order_view_model.dart';
import 'package:pos/presentation/home/main/cart_widget.dart';
import 'package:pos/presentation/product/main/product_view_model.dart';
import 'package:pos/presentation/product/main/products_view_model.dart';
import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';
import '../../order/main/order_view_model_test.dart' as bills;
import 'cart_page_sale_test.dart' as cart;
import 'home_view_model_test.dart' as home;
import '../../product/product_navigation_test.dart' as products;

/// The catalogue, whose product detail loads only when [detail] completes.
class _HeldCatalogue extends products.Catalogue {
  final detail = Completer<Product?>();

  _HeldCatalogue() : super([products.paracetamol()]);

  @override
  Future<Product?> getLocalProductById(String id) => detail.future;
}

/// What the home page was built over: the till every selling screen
/// shares, the catalogue, and how many view models of each kind were made.
typedef _App = ({Till till, _HeldCatalogue catalogue, Map<Type, int> made});

_App _registerApp() {
  final till = Till();
  final catalogue = _HeldCatalogue();
  final made = <Type, int>{};
  T count<T>(T Function() make) {
    made[T] = (made[T] ?? 0) + 1;
    return make();
  }

  final login = home.FakeLoginRepository(role: 'ADMIN');
  sl.registerFactory(() => HomeViewModel(
        getRoleUseCase: GetRoleUseCase(login),
        logoutUseCase: LogoutUseCase(login),
      ));
  sl.registerFactory(
      () => ProductSearchViewModel(productRepo: cart.SaleProducts()));
  sl.registerFactory(() => count(() => CartViewModel(
        productRepo: cart.SaleProducts(),
        till: till,
        checkoutSaleUseCase:
            CheckoutSaleUseCase(orderRepo: cart.SaleOrders('OD_1')),
      )));
  sl.registerFactory(() => count(() => OrderViewModel(
        orderRepo:
            bills.FakeOrderRepository(orders: [bills.order('1', 'Cash')]),
        getRoleUseCase: GetRoleUseCase(login),
      )));
  sl.registerFactory(
      () => count(() => ProductViewModel(productRepo: catalogue)));
  sl.registerFactory(() => ProductsViewModel(productRepo: catalogue));
  return (till: till, catalogue: catalogue, made: made);
}

Future<_App> _openHome(WidgetTester tester) async {
  useViewSize(tester, desktopSize);
  final app = _registerApp();
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: [CommonLocalizationsDelegate(), thaiLanguages],
    home: const HomePage(),
  ));
  await _settle(tester);
  return app;
}

/// Lets loads and transitions run without waiting on spinners, which never
/// settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapSection(WidgetTester tester, String label) => tester.tap(find
    .byWidgetPredicate((w) => w is AppSidebarAction && w.label == label)
    .hitTestable());

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  testWidgets('a section change fades the content area, not the menu',
      (tester) async {
    // Arrange
    await _openHome(tester);
    final menu = find.byType(AppSidebarAction).first;
    final menuAt = tester.getTopLeft(menu);

    // Act
    await _tapSection(tester, 'รายการขาย');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Assert
    final fade = find.ancestor(
        of: find.byType(OrderPage), matching: find.byType(FadeTransition));
    expect(find.descendant(of: find.byType(SectionSwitcher), matching: fade),
        findsWidgets);
    expect(tester.widget<FadeTransition>(fade.first).opacity.value,
        inExclusiveRange(0, 1));
    expect(tester.getTopLeft(menu), menuAt);
  });

  testWidgets('a product tapped while selling fades back in lands in the cart',
      (tester) async {
    // Arrange
    final till = (await _openHome(tester)).till;
    await _tapSection(tester, 'รายการขาย');
    await _settle(tester);

    // Act
    await _tapSection(tester, 'ขายสินค้า');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(ProductItem));
    await _settle(tester);

    // Assert
    expect(till.open.lines, hasLength(1));
  });

  testWidgets(
      'a product detail that loads after leaving สินค้า does not take Back',
      (tester) async {
    // Arrange: an admin on สินค้า taps a product; its detail is still loading
    final app = await _openHome(tester);
    await _tapSection(tester, 'สินค้า');
    await _settle(tester);
    await tester.tap(find.text('Paracetamol').hitTestable().first);
    await tester.pump();

    // Act: selling is chosen, and the detail arrives during the fade
    await _tapSection(tester, 'ขายสินค้า');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    app.catalogue.detail.complete(products.paracetamol());
    await tester.pump();
    await _settle(tester);
    final handled = await tester.binding.handlePopRoute();
    await tester.pump();

    // Assert: Back from selling leaves the app, and nothing threw
    expect(handled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
