// An address typed into the running web app (the engine's pushRoute) opens
// an admin page only for an admin: anyone else ends on the selling screen
// without seeing it, and nobody sees it before the role is known.

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/localizations/localizations_delegate.dart';
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:um/domain/entities/user/user.dart';
import 'package:um/domain/repositories/user_repository.dart';
import 'package:um/domain/usecase/auth_use_cases.dart';
import 'package:um/domain/usecase/user_use_cases.dart';
import 'package:um/presentation/constants.dart';
import 'package:um/presentation/user/list/users_page.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/category/add/category_add_page.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/home/main/home_page.dart';
import 'package:pos/presentation/home/main/home_view_model.dart';
import 'package:pos/presentation/product/expired/products_expired_page.dart';
import 'package:pos/presentation/product/main/product_page.dart';
import 'package:pos/presentation/router.dart';
import '../support/app_fonts.dart';
import '../support/app_languages.dart';
import 'category/add/category_add_view_model_test.dart' as category_add;
import 'home/main/cart_page_sale_test.dart' as cart;
import 'home/main/home_view_model_test.dart' as home;

/// The selling screen, recognised by its cart's title.
final _sellingScreen = find.text('ตะกร้าสินค้า #1');

/// A shop with no other users, for the users list.
class _NoUsers implements UserRepository {
  @override
  Future<List<User>> getUsers() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// A session whose role comes back when [role] completes.
class _PendingRole extends home.FakeLoginRepository {
  final Future<String> pendingRole;

  _PendingRole(this.pendingRole);

  @override
  Future<String> getRole() => pendingRole;
}

Future<void> _openApp(
    WidgetTester tester, home.FakeLoginRepository login) async {
  useViewSize(tester, phoneSize);
  cart.registerSellingScreen('OD_1');
  sl.registerFactory(() => HomeViewModel(
        getRoleUseCase: GetRoleUseCase(login),
        logoutUseCase: LogoutUseCase(login),
      ));
  sl.registerFactory(
      () => category_add.buildViewModel(category_add.FakeCategoryRepository()));
  sl.registerFactory(() => GetUsersUseCase(_NoUsers()));
  sl.registerFactory(() => SetPasswordUseCase(_NoUsers()));
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: [CommonLocalizationsDelegate(), thaiLanguages],
    onGenerateRoute: RouterApp.generateRoute,
    home: const HomePage(),
  ));
  await _settle(tester);
}

/// Lets loads and route transitions run without waiting on spinners.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The address typed into the browser's bar while the app runs.
Future<void> _typeAddress(WidgetTester tester, String address) async {
  await tester.binding.handlePushRoute(address);
  await _settle(tester);
}

/// Admin pages, by the address that opens them and the page it shows.
final _adminPages = <String, Type>{
  productExpiredRoute: ProductsExpiredPage,
  categoryAddRoute: CategoryAddPage,
  routeUsers: UsersPage,
};

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  for (final role in ['USER', 'MANAGER']) {
    for (final MapEntry(key: address, value: page) in _adminPages.entries) {
      testWidgets('a $role who types $address stays on the selling screen',
          (tester) async {
        // Arrange
        await _openApp(tester, home.FakeLoginRepository(role: role));

        // Act
        await _typeAddress(tester, address);

        // Assert
        expect(find.byType(page), findsNothing);
        expect(_sellingScreen, findsOneWidget);
      });
    }

    testWidgets('a $role who types /products sees no product list',
        (tester) async {
      // Arrange
      await _openApp(tester, home.FakeLoginRepository(role: role));

      // Act
      await _typeAddress(tester, '/products');

      // Assert
      expect(find.byType(ProductsPage), findsNothing);
    });
  }

  testWidgets('an admin who types an admin address gets the page',
      (tester) async {
    for (final address in [categoryAddRoute, routeUsers]) {
      // Arrange
      await _openApp(tester, home.FakeLoginRepository(role: 'ADMIN'));

      // Act
      await _typeAddress(tester, address);

      // Assert
      expect(find.byType(_adminPages[address]!), findsOneWidget,
          reason: address);
      await sl.reset();
    }
  });

  testWidgets('an admin page shows nothing of itself before the role is known',
      (tester) async {
    // Arrange
    final role = Completer<String>();
    await _openApp(tester, _PendingRole(role.future));

    // Act
    await _typeAddress(tester, categoryAddRoute);

    // Assert: waiting, on a page of its own
    expect(find.byType(CategoryAddPage), findsNothing);
    expect(
        find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(CircularProgressIndicator)),
        findsWidgets);

    // Act: the role turns out to be a user's
    role.complete('USER');
    await _settle(tester);

    // Assert
    expect(find.byType(CategoryAddPage), findsNothing);
    expect(_sellingScreen, findsOneWidget);
  });
}
