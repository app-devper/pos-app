// System Back (Android's button, the browser's Back on the web) inside the
// app: an inner page returns to the page it was opened from, and only the
// selling screen leaves the app.

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
import 'package:pos/presentation/customer/add/customer_add_view_model.dart';
import 'package:pos/presentation/customer/main/customer_view_model.dart';
import 'package:pos/presentation/customer/main/customers_view_model.dart';
import 'package:pos/presentation/home/main/home_page.dart';
import 'package:pos/presentation/home/main/home_view_model.dart';
import 'package:pos/presentation/receive/main/receives_view_model.dart';
import 'package:pos/presentation/router.dart';
import '../support/app_fonts.dart';
import '../support/app_languages.dart';
import 'customer/main/customer_page_test.dart' as customers;
import 'home/main/cart_page_sale_test.dart' as cart;
import 'home/main/home_view_model_test.dart' as home;
import 'receive/main/receives_view_model_test.dart' as receipts;

/// The จัดการ landing page, recognised by a tile only it shows.
final _managePage = find.text('จัดการลูกค้า');

void _registerApp() {
  cart.registerSellingScreen('OD_202611260001');
  final login = home.FakeLoginRepository(role: 'ADMIN');
  sl.registerFactory(() => HomeViewModel(
        getRoleUseCase: GetRoleUseCase(login),
        logoutUseCase: LogoutUseCase(login),
      ));
  sl.registerFactory(() => ReceivesViewModel(
      receiveRepo: receipts.FakeReceiveRepository(
          receives: [receipts.buildReceive('1', 'RC-1')])));
  final people = customers.ServerCustomers();
  sl.registerFactory(() => CustomersViewModel(customerRepo: people));
  sl.registerFactory(() => CustomerViewModel(customerRepo: people));
  sl.registerFactory(() => CustomerAddViewModel(customerRepo: people));
}

/// Lets loads and route transitions run without waiting on spinners, which
/// never settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The app as the router builds it, signed in as an admin, on the selling
/// screen.
Future<void> _openApp(WidgetTester tester, {Size size = phoneSize}) async {
  useViewSize(tester, size);
  _registerApp();
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: [CommonLocalizationsDelegate(), thaiLanguages],
    onGenerateRoute: RouterApp.generateRoute,
    home: const HomePage(),
  ));
  await _settle(tester);
}

/// Opens the shell section [label] from the side menu (the drawer on a
/// phone).
Future<void> _openSection(WidgetTester tester, String label) async {
  final menu = find.byTooltip('เมนู');
  if (menu.hitTestable().evaluate().isNotEmpty) {
    await tester.tap(menu.hitTestable());
    await _settle(tester);
  }
  await tester.tap(find
      .byWidgetPredicate((w) => w is AppSidebarAction && w.label == label)
      .hitTestable());
  await _settle(tester);
}

/// The selling screen, recognised by its cart's title.
final _sellingScreen = find.text('ตะกร้าสินค้า #1');

Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await _settle(tester);
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  testWidgets('system Back on the receipts list returns to จัดการ',
      (tester) async {
    // Arrange
    await _openApp(tester);
    await _openSection(tester, 'จัดการ');
    await tester.tap(find.text('ใบรับสินค้า / Goods Receipt'));
    await _settle(tester);
    expect(find.text('RC-1').hitTestable(), findsOneWidget);

    // Act
    await _systemBack(tester);

    // Assert
    expect(_managePage.hitTestable(), findsOneWidget);
    expect(find.text('RC-1'), findsNothing);
  });

  testWidgets('system Back on the customer list returns to จัดการ',
      (tester) async {
    // Arrange
    await _openApp(tester);
    await _openSection(tester, 'จัดการ');
    await tester.tap(find.text('จัดการลูกค้า'));
    await _settle(tester);
    expect(find.text('ลูกค้าเดิม').hitTestable(), findsOneWidget);

    // Act
    await _systemBack(tester);

    // Assert
    expect(_managePage.hitTestable(), findsOneWidget);
    expect(find.text('ลูกค้าเดิม'), findsNothing);
  });

  testWidgets('system Back on จัดการ goes to the selling screen',
      (tester) async {
    // Arrange
    await _openApp(tester);
    await _openSection(tester, 'จัดการ');

    // Act
    final handled = await tester.binding.handlePopRoute();
    await _settle(tester);

    // Assert
    expect(handled, isTrue);
    expect(_sellingScreen.hitTestable(), findsOneWidget);
  });

  testWidgets('system Back on the selling screen leaves the app',
      (tester) async {
    // Arrange
    await _openApp(tester);

    // Act
    final handled = await tester.binding.handlePopRoute();

    // Assert
    expect(handled, isFalse);
  });

  testWidgets('system Back with the drawer open closes only the drawer',
      (tester) async {
    // Arrange
    await _openApp(tester);
    await _openSection(tester, 'จัดการ');
    await tester.tap(find.byTooltip('เมนู'));
    await _settle(tester);

    // Act
    await _systemBack(tester);

    // Assert
    expect(_managePage.hitTestable(), findsOneWidget);
  });

  testWidgets('system Back with a dialog open closes only the dialog',
      (tester) async {
    // Arrange
    await _openApp(tester);
    await _openSection(tester, 'จัดการ');
    await tester.tap(find.text('ใบรับสินค้า / Goods Receipt'));
    await _settle(tester);
    await tester.tap(find.byTooltip('เมนูใบรับสินค้า'));
    await _settle(tester);
    expect(find.text('เพิ่มใบรับสินค้า').hitTestable(), findsOneWidget);

    // Act
    await _systemBack(tester);

    // Assert
    expect(find.text('เพิ่มใบรับสินค้า'), findsNothing);
    expect(find.text('RC-1').hitTestable(), findsOneWidget);
  });
}
