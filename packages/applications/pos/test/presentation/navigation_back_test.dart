// System Back (Android's button, the browser's Back on the web) inside the
// app: an inner page returns to the page it was opened from, and only the
// selling screen leaves the app.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:common/config/app_config.dart';
import 'package:common/localizations/localizations_delegate.dart';
import 'package:design_system/theme/theme.dart';
import 'package:design_system/widgets/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:um/domain/entities/auth/login.dart';
import 'package:um/domain/entities/auth/system.dart';
import 'package:um/domain/usecase/auth_use_cases.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/customer/add/customer_add_view_model.dart';
import 'package:pos/presentation/customer/main/customer_view_model.dart';
import 'package:pos/presentation/customer/main/customers_view_model.dart';
import 'package:pos/presentation/home/main/home_page.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/presentation/home/main/home_view_model.dart';
import 'package:pos/presentation/order/detail/order_detail_view_model.dart';
import 'package:pos/presentation/order/main/order_view_model.dart';
import 'package:pos/presentation/product/edit/product_edit_view_model.dart';
import 'package:pos/presentation/product/main/product_view_model.dart';
import 'package:pos/presentation/product/main/products_view_model.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_view_model.dart';
import 'package:pos/presentation/receive/main/receives_view_model.dart';
import 'package:pos/presentation/router.dart';
import '../support/app_fonts.dart';
import '../support/app_languages.dart';
import 'customer/main/customer_page_test.dart' as customers;
import 'home/main/cart_page_sale_test.dart' as cart;
import 'home/main/home_view_model_test.dart' as home;
import 'order/detail/order_detail_view_model_test.dart' as bill;
import 'order/main/order_view_model_test.dart' as bills;
import 'product/product_navigation_test.dart' as products;
import 'stock_count/manage/stock_count_manage_view_model_test.dart' as counts;
import 'supplier/info/supplier_info_view_model_test.dart' as shop;
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
  _registerProducts();
  _registerBills(login);
  sl.registerFactory(() =>
      StockCountsViewModel(stockCountRepo: counts.FakeStockCountRepository()));
  sl.registerFactory(() => shop.buildViewModel(shop.FakeSupplierRepository()));
  final people = customers.ServerCustomers();
  sl.registerFactory(() => CustomersViewModel(customerRepo: people));
  sl.registerFactory(() => CustomerViewModel(customerRepo: people));
  sl.registerFactory(() => CustomerAddViewModel(customerRepo: people));
}

void _registerProducts() {
  final catalogue = products.Catalogue([products.paracetamol()]);
  sl.registerFactory(() => ProductViewModel(productRepo: catalogue));
  sl.registerFactory(() => ProductsViewModel(productRepo: catalogue));
  sl.registerFactory(() => ProductEditViewModel(productRepo: catalogue));
}

/// One bill, OD-1, listed and opened as the detail of bill OD_DETAIL.
void _registerBills(home.FakeLoginRepository login) {
  sl.registerFactory(() => OrderViewModel(
        orderRepo:
            bills.FakeOrderRepository(orders: [bills.order('1', 'Cash')]),
        getRoleUseCase: GetRoleUseCase(login),
      ));
  sl.registerFactory(() => OrderDetailViewModel(
        getRoleUseCase: GetRoleUseCase(login),
        orderRepo: bill.FakeOrderRepository(
            orderDetail: OrderDetail(
          id: '1',
          createdDate: '2026-11-26T10:00:00Z',
          items: const [],
          total: 100,
          totalCost: 40,
          discount: 0,
          type: 'Cash',
          code: 'OD_DETAIL',
          customerCode: '',
          customerName: '',
        )),
        supplierRepo: bill.FakeSupplierRepository(
            supplier: Supplier(
                id: 's1', name: 'ร้าน', address: '', phone: '', taxId: '')),
        customerRepo: bill.FakeCustomerRepository(),
        productRepo: products.Catalogue(const []),
      ));
}

/// A stored session that is still alive, for the POS system.
class _LiveSession extends home.FakeLoginRepository {
  _LiveSession() : super(role: 'ADMIN');

  @override
  Future<Login> keepAlive() async => Login(accessToken: 'token');

  @override
  Future<System> getSystem() async => System(
      id: 's', clientId: 'c', systemName: 'POS', systemCode: 'POS', host: '');
}

/// The app reloaded in the browser at [address], with a live session: the
/// splash page checks the session first, as at every start.
Future<void> _reloadAt(WidgetTester tester, String address) async {
  useViewSize(tester, phoneSize);
  _registerApp();
  sl.registerLazySingleton(() => AppConfig(
      apiUrl: '', logo: '', name: 'POS', system: 'POS', home: homeRoute));
  sl.registerFactory(() => RestoreSessionUseCase(_LiveSession()));
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: [CommonLocalizationsDelegate(), thaiLanguages],
    onGenerateRoute: RouterApp.generateRoute,
    onGenerateInitialRoutes: RouterApp.generateInitialRoutes,
    initialRoute: address,
  ));
  await _settle(tester);
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

/// The addresses the app reports to the browser, in order.
List<String> _watchAddress(WidgetTester tester) {
  final addresses = <String>[];
  tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.navigation, (call) async {
    if (call.method == 'routeInformationUpdated') {
      final args = call.arguments as Map<Object?, Object?>;
      addresses.add('${args['uri'] ?? args['location']}');
    }
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.navigation, null));
  return addresses;
}

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
    await tester.tap(find.byTooltip('คำสั่งเพิ่มเติม'));
    await _settle(tester);
    expect(find.text('เพิ่มใบรับสินค้า').hitTestable(), findsOneWidget);

    // Act
    await _systemBack(tester);

    // Assert
    expect(find.text('เพิ่มใบรับสินค้า'), findsNothing);
    expect(find.text('RC-1').hitTestable(), findsOneWidget);
  });

  testWidgets('system Back on the stock counts list returns to จัดการ',
      (tester) async {
    // Arrange
    await _openApp(tester);
    await _openSection(tester, 'จัดการ');
    await tester.tap(find.text('นับสต็อก'));
    await _settle(tester);
    expect(_managePage.hitTestable(), findsNothing);

    // Act
    await _systemBack(tester);

    // Assert
    expect(_managePage.hitTestable(), findsOneWidget);
  });

  testWidgets('system Back on a bill detail returns to the bills list',
      (tester) async {
    // Arrange
    await _openApp(tester);
    await _openSection(tester, 'รายการขาย');
    await tester.tap(find.text('OD-1'));
    await _settle(tester);
    expect(find.textContaining('OD_DETAIL').hitTestable(), findsWidgets);

    // Act
    await _systemBack(tester);

    // Assert
    expect(find.textContaining('OD_DETAIL'), findsNothing);
    expect(find.text('OD-1').hitTestable(), findsOneWidget);
  });

  for (final size in [phoneSize, desktopSize]) {
    testWidgets('system Back on a product detail returns to the list at $size',
        (tester) async {
      // Arrange
      await _openApp(tester, size: size);
      await _openSection(tester, 'สินค้า');
      await tester.tap(find.text('Paracetamol').hitTestable().first);
      await _settle(tester);
      expect(find.text('ข้อมูลทั่วไป').hitTestable(), findsWidgets);

      // Act
      await _systemBack(tester);

      // Assert
      expect(find.text('ข้อมูลทั่วไป'), findsNothing);
      expect(_sellingScreen, findsNothing);
      expect(find.text('Paracetamol').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('system Back on the add-customer form returns to the list',
      (tester) async {
    // Arrange
    await _openApp(tester);
    await _openSection(tester, 'จัดการ');
    await tester.tap(find.text('จัดการลูกค้า'));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.add).hitTestable());
    await _settle(tester);
    expect(find.text('ลูกค้าเดิม').hitTestable(), findsNothing);

    // Act
    await _systemBack(tester);

    // Assert
    expect(find.text('ลูกค้าเดิม').hitTestable(), findsOneWidget);
  });

  for (final (tile, title) in [
    ('ใบรับสินค้า / Goods Receipt', 'รายการรับสินค้า'),
    ('นับสต็อก', 'นับสต็อก'),
    ('จัดการลูกค้า', 'ข้อมูลลูกค้า'),
  ]) {
    for (final size in [phoneSize, desktopSize]) {
      testWidgets(
          '$tile starts its header with a back arrow named ย้อนกลับ, '
          'not the menu, at $size', (tester) async {
        // Arrange
        await _openApp(tester, size: size);
        await _openSection(tester, 'จัดการ');
        await tester.tap(find.text(tile));
        await _settle(tester);
        final arrow = find.byTooltip('ย้อนกลับ').hitTestable();

        // Assert
        expect(arrow, findsOneWidget);
        expect(find.byTooltip('เมนู').hitTestable(), findsNothing);
        expect(find.byIcon(Icons.arrow_back).hitTestable(), findsOneWidget);
        final heading = find.text(title).hitTestable().last;
        expect(tester.getCenter(arrow).dx,
            lessThan(tester.getTopLeft(heading).dx));

        // Act
        await tester.tap(arrow);
        await _settle(tester);

        // Assert
        expect(_managePage.hitTestable(), findsOneWidget);
      });
    }
  }

  testWidgets(
      'on a wide screen the side menu stays beside a page opened from '
      'จัดการ and still leads to every section', (tester) async {
    // Arrange
    await _openApp(tester, size: desktopSize);
    await _openSection(tester, 'จัดการ');
    await tester.tap(find.text('ใบรับสินค้า / Goods Receipt'));
    await _settle(tester);
    expect(find.text('RC-1').hitTestable(), findsOneWidget);

    // Act
    await _openSection(tester, 'ขายสินค้า');

    // Assert
    expect(_sellingScreen.hitTestable(), findsOneWidget);
    expect(find.text('RC-1'), findsNothing);
  });

  for (final (section, tile) in [
    ('สินค้า', null),
    ('จัดการ', 'ใบรับสินค้า / Goods Receipt'),
  ]) {
    testWidgets(
        'the ${tile ?? section} list on a phone shows one menu at most: '
        'its commands sit behind คำสั่งเพิ่มเติม', (tester) async {
      // Arrange
      await _openApp(tester);
      await _openSection(tester, section);
      if (tile != null) {
        await tester.tap(find.text(tile));
        await _settle(tester);
      }

      expect(find.byIcon(Icons.menu).evaluate().length, lessThanOrEqualTo(1));
      expect(find.byIcon(Icons.more_vert).hitTestable(), findsOneWidget);

      // Act
      await tester.tap(find.byTooltip('คำสั่งเพิ่มเติม').hitTestable());
      await _settle(tester);

      // Assert
      expect(find.textContaining('เพิ่ม').hitTestable(), findsWidgets);
    });
  }

  for (final (tile, address) in [
    ('ใบรับสินค้า / Goods Receipt', '/receives'),
    ('จัดการลูกค้า', '/customers'),
    ('นับสต็อก', '/stock-counts'),
    ('ร้านค้าของฉัน', '/supplier'),
  ]) {
    testWidgets('$tile puts $address in the address bar, and Back takes it off',
        (tester) async {
      // Arrange
      final addresses = _watchAddress(tester);
      await _openApp(tester);
      await _openSection(tester, 'จัดการ');

      // Act
      await tester.tap(find.text(tile));
      await _settle(tester);
      final opened = addresses.isEmpty ? null : addresses.last;
      await _systemBack(tester);

      // Assert
      expect(opened, address);
      expect(addresses.last, isNot(address));
    });
  }

  testWidgets('a reload at the receipts address shows the receipts again',
      (tester) async {
    // Arrange / Act
    await _reloadAt(tester, receivesRoute);

    // Assert
    expect(find.text('RC-1').hitTestable(), findsOneWidget);

    // Act
    await _systemBack(tester);

    // Assert
    expect(_managePage.hitTestable(), findsOneWidget);
  });

  testWidgets('a start at the splash address ends on the selling screen',
      (tester) async {
    // Arrange / Act
    await _reloadAt(tester, '/um-splash');

    // Assert
    expect(_sellingScreen.hitTestable(), findsOneWidget);
  });
}
