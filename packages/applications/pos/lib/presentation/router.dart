// Flutter imports:
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Package imports:
import 'package:um/presentation/constants.dart';
import 'package:um/presentation/router.dart';

// Project imports:
import 'package:pos/presentation/category/add/category_add_page.dart';
import 'package:pos/presentation/category/argument.dart';
import 'package:pos/presentation/category/edit/category_edit_page.dart';
import 'package:pos/presentation/category/main/category_page.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/core/admin_only.dart';
import 'package:pos/presentation/customer/main/customer_page.dart';
import 'package:pos/presentation/home/main/home_page.dart';
import 'package:pos/presentation/home/main/inner_page_frame.dart';
import 'package:pos/presentation/home/scanner/scanner_page.dart';
import 'package:pos/presentation/order/argument.dart';
import 'package:pos/presentation/order/detail/order_detail_page.dart';
import 'package:pos/presentation/order/history/order_history_page.dart';
import 'package:pos/presentation/product/argument.dart';
import 'package:pos/presentation/product/edit/product_edit_page.dart';
import 'package:pos/presentation/product/expired/products_expired_page.dart';
import 'package:pos/presentation/product/lot_edit/product_lot_edit_page.dart';
import 'package:pos/presentation/receive/argument.dart';
import 'package:pos/presentation/receive/main/receive_page.dart';
import 'package:pos/presentation/receive/manage/receive_manage_page.dart';
import 'package:pos/presentation/stock_count/argument.dart';
import 'package:pos/presentation/stock_count/main/stock_counts_page.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_manage_page.dart';
import 'package:pos/presentation/supplier/add/supplier_add_page.dart';
import 'package:pos/presentation/supplier/argument.dart';
import 'package:pos/presentation/supplier/edit/supplier_edit_page.dart';
import 'package:pos/presentation/supplier/info/supplier_info_page.dart';
import 'package:pos/presentation/supplier/main/suppliers_page.dart';

class RouterApp {
  /// A list opened from จัดการ: pushed over it, with the side menu kept
  /// beside it on a wide screen.
  static Route<dynamic> _manageList(RouteSettings settings,
      {required WidgetBuilder builder}) {
    return MaterialPageRoute(
        settings: settings,
        builder: (context) => InnerPageFrame(child: builder(context)));
  }

  /// A form or record opened from จัดการ or one of its lists: pushed over
  /// it with its back arrow only. A side menu there would leave the form,
  /// and its unsaved work, without asking.
  static Route<dynamic> _manageForm(RouteSettings settings,
          {required WidgetBuilder builder}) =>
      _adminOnly(settings, builder: builder);

  /// A page only an admin reaches through the app (from สินค้า, จัดการ or
  /// an admin's bill line): an address typed into the browser does not
  /// open it for anyone else. What it is handed is read only when it is
  /// built, so a typed address without it does not fail first.
  static Route<T> _adminOnly<T>(RouteSettings settings,
      {required WidgetBuilder builder}) {
    return MaterialPageRoute<T>(
        settings: settings,
        builder: (context) => AdminOnly(child: Builder(builder: builder)));
  }

  /// The um pages only an admin reaches (the users list and its forms).
  static const _adminUmRoutes = {
    routeUsers,
    routeUserAdd,
    routeUserEdit,
    routeUserHome
  };

  /// A um page, gated as [_adminOnly] when only an admin reaches it.
  static Route<dynamic> _umRoute(RouteSettings settings) {
    final route = RouterUm.generateRoute(settings);
    if (!_adminUmRoutes.contains(settings.name)) return route;
    if (route is! MaterialPageRoute) {
      throw StateError('RouterUm returned ${route.runtimeType} for '
          '${settings.name}; it cannot be gated');
    }
    return MaterialPageRoute<dynamic>(
        settings: route.settings,
        builder: (context) =>
            AdminOnly(child: Builder(builder: route.builder)));
  }

  /// The routes the app starts with, whatever [initialRoute] (the
  /// browser's address on a reload or a typed link) says: only the splash
  /// page, which checks the session and then opens home. A page that needs
  /// what the page before handed it cannot be rebuilt from an address, and
  /// a page must never open before the session and role are known.
  static List<Route<dynamic>> generateInitialRoutes(String initialRoute) =>
      [generateRoute(const RouteSettings(name: rootRoute))];

  /// Every route carries the name it was asked for, so the browser's
  /// address follows the page shown and its Back pops to the parent.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (settings.name?.startsWith('/um') ?? false) {
      return _umRoute(settings);
    } else {
      switch (settings.name) {
        case homeRoute:
          final section = settings.arguments as String?;
          return MaterialPageRoute(
              settings: settings, builder: (_) => HomePage(section: section));
        case productEditRoute:
          // Pushed from an Order's lines (an Admin taps one) and from the
          // scanner. There was no case for it, so both fell through to
          // "Page Not Found". A non-null result tells the caller something
          // changed and it should reload.
          return _adminOnly<bool>(
            settings,
            builder: (context) => Scaffold(
              body: SafeArea(
                child: ProductEditPage(
                  product: (settings.arguments as ProductArgument).product,
                  onBack: () => Navigator.pop(context),
                  onEdit: () => Navigator.pop(context, true),
                  onRemove: () => Navigator.pop(context, true),
                ),
              ),
            ),
          );
        case productExpiredRoute:
          return _adminOnly(settings,
              builder: (_) => const ProductsExpiredPage());
        case productLotEditRoute:
          return _adminOnly(settings,
              builder: (_) => ProductLotEditPage(
                  productLot:
                      (settings.arguments as ProductLotArgument).productLot));
        case orderDetailRoute:
          final args = settings.arguments as OrderArgument;
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => OrderDetailPage(orderId: args.orderId));
        case orderHistoryRoute:
          // From an admin's bill line menu.
          return _adminOnly(settings,
              builder: (_) => OrderHistoryPage(
                  product:
                      (settings.arguments as OrderHistoryArgument).product));
        case categoriesRoute:
          return _manageList(settings, builder: (_) => const CategoryPage());
        case categoryAddRoute:
          return _manageForm(settings, builder: (_) => const CategoryAddPage());
        case categoryEditRoute:
          return _manageForm(settings,
              builder: (_) => CategoryEditPage(
                  category: (settings.arguments as CategoryArgument).category));
        case supplierRoute:
          // Open to every role: a bill's receipt sends anyone who prints
          // one here when the shop has no profile yet.
          return MaterialPageRoute(
              settings: settings, builder: (_) => const SupplierInfoPage());
        case suppliersRoute:
          return _manageList(settings, builder: (_) => const SuppliersPage());
        case supplierAddRoute:
          return _manageForm(settings, builder: (_) => const SupplierAddPage());
        case supplierEditRoute:
          return _manageForm(settings,
              builder: (_) => SupplierEditPage(
                  supplier: (settings.arguments as SupplierArgument).supplier));
        case customersRoute:
          // The list draws its own header (title and back arrow).
          return _manageList(
            settings,
            builder: (context) => Scaffold(
              body: SafeArea(
                child: CustomerPage(onBack: () => Navigator.maybePop(context)),
              ),
            ),
          );
        case receivesRoute:
          return _manageList(settings, builder: (_) => const ReceivePage());
        case receiveManageRoute:
          return _manageForm(settings,
              builder: (_) => ReceiveManagePage(
                  receiveId: (settings.arguments as ReceiveManageArgument?)
                      ?.receiveId));
        case stockCountsRoute:
          return _manageList(settings, builder: (_) => const StockCountsPage());
        case stockCountManageRoute:
          return _manageForm(settings,
              builder: (_) => StockCountManagePage(
                  stockCountId:
                      (settings.arguments as StockCountManageArgument?)
                          ?.stockCountId));
        case scanRoute:
          if (kIsWeb) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: const Text('Scanner'),
                ),
                body: const Center(
                  child: Text('Scanner is not available on web'),
                ),
              ),
            );
          }
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ScannerPage(mode: "SCAN"));
        case rootRoute:
          return RouterUm.generateRoute(const RouteSettings(name: routeSplash));
        default:
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body: const Center(
                child: Text('Page Not Found'),
              ),
            ),
          );
      }
    }
  }
}
