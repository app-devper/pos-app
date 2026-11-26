// Switching the shell's sections on the real home page: the content area
// cross-fades, and the selling screen takes a tap while it fades in.

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
import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';
import '../../order/main/order_view_model_test.dart' as bills;
import 'cart_page_sale_test.dart' as cart;
import 'home_view_model_test.dart' as home;

/// The till every selling screen shares, as the app registers it.
Till _registerApp() {
  final till = Till();
  final login = home.FakeLoginRepository(role: 'ADMIN');
  sl.registerFactory(() => HomeViewModel(
        getRoleUseCase: GetRoleUseCase(login),
        logoutUseCase: LogoutUseCase(login),
      ));
  sl.registerFactory(
      () => ProductSearchViewModel(productRepo: cart.SaleProducts()));
  sl.registerFactory(() => CartViewModel(
        productRepo: cart.SaleProducts(),
        till: till,
        checkoutSaleUseCase:
            CheckoutSaleUseCase(orderRepo: cart.SaleOrders('OD_1')),
      ));
  sl.registerFactory(() => OrderViewModel(
        orderRepo:
            bills.FakeOrderRepository(orders: [bills.order('1', 'Cash')]),
        getRoleUseCase: GetRoleUseCase(login),
      ));
  return till;
}

Future<Till> _openHome(WidgetTester tester) async {
  useViewSize(tester, desktopSize);
  final till = _registerApp();
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: [CommonLocalizationsDelegate(), thaiLanguages],
    home: const HomePage(),
  ));
  await _settle(tester);
  return till;
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
    final till = await _openHome(tester);
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
}
