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
import 'package:pos/presentation/customer/main/customer_page.dart';
import 'package:pos/presentation/home/main/home_page.dart';
import 'package:pos/presentation/home/main/inner_page_frame.dart';
import 'package:pos/presentation/home/scanner/scanner_page.dart';
import 'package:pos/presentation/order/argument.dart';
import 'package:pos/presentation/order/detail/order_detail_page.dart';
import 'package:pos/presentation/order/history/order_history_page.dart';
import 'package:pos/presentation/order/main/order_page.dart';
import 'package:pos/presentation/product/argument.dart';
import 'package:pos/presentation/product/edit/product_edit_page.dart';
import 'package:pos/presentation/product/expired/products_expired_page.dart';
import 'package:pos/presentation/product/lot_edit/product_lot_edit_page.dart';
import 'package:pos/presentation/product/main/product_page.dart';
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
  /// A page opened from จัดการ (or from one of its pages): pushed over it,
  /// with the side menu kept beside it on a wide screen.
  static Route<dynamic> _managePage(RouteSettings settings,
      {required WidgetBuilder builder}) {
    return MaterialPageRoute(
        settings: settings,
        builder: (context) => InnerPageFrame(child: builder(context)));
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
      return RouterUm.generateRoute(settings);
    } else {
      switch (settings.name) {
        case homeRoute:
          final section = settings.arguments as String?;
          return MaterialPageRoute(
              settings: settings, builder: (_) => HomePage(section: section));
        case productsRoute:
          final args = settings.arguments as ProductsArgument?;
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProductsPage(mode: args?.mode));
        case productEditRoute:
          // Pushed from an Order's lines (an Admin taps one) and from the
          // scanner. There was no case for it, so both fell through to
          // "Page Not Found". A non-null result tells the caller something
          // changed and it should reload.
          final args = settings.arguments as ProductArgument;
          return MaterialPageRoute<bool>(
            settings: settings,
            builder: (context) => Scaffold(
              body: SafeArea(
                child: ProductEditPage(
                  product: args.product,
                  onBack: () => Navigator.pop(context),
                  onEdit: () => Navigator.pop(context, true),
                  onRemove: () => Navigator.pop(context, true),
                ),
              ),
            ),
          );
        case productExpiredRoute:
          return MaterialPageRoute(
              settings: settings, builder: (_) => const ProductsExpiredPage());
        case productLotEditRoute:
          final args = settings.arguments as ProductLotArgument;
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProductLotEditPage(productLot: args.productLot));
        case ordersRoute:
          return MaterialPageRoute(
              settings: settings, builder: (_) => const OrderPage());
        case orderDetailRoute:
          final args = settings.arguments as OrderArgument;
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => OrderDetailPage(orderId: args.orderId));
        case orderHistoryRoute:
          final args = settings.arguments as OrderHistoryArgument;
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => OrderHistoryPage(product: args.product));
        case categoriesRoute:
          return _managePage(settings, builder: (_) => const CategoryPage());
        case categoryAddRoute:
          return _managePage(settings, builder: (_) => const CategoryAddPage());
        case categoryEditRoute:
          final args = settings.arguments as CategoryArgument;
          return _managePage(settings,
              builder: (_) => CategoryEditPage(category: args.category));
        case supplierRoute:
          return _managePage(settings,
              builder: (_) => const SupplierInfoPage());
        case suppliersRoute:
          return _managePage(settings, builder: (_) => const SuppliersPage());
        case supplierAddRoute:
          return _managePage(settings, builder: (_) => const SupplierAddPage());
        case supplierEditRoute:
          final args = settings.arguments as SupplierArgument;
          return _managePage(settings,
              builder: (_) => SupplierEditPage(supplier: args.supplier));
        case customersRoute:
          // The list draws its own header (title and back arrow).
          return _managePage(
            settings,
            builder: (context) => Scaffold(
              body: SafeArea(
                child: CustomerPage(onBack: () => Navigator.maybePop(context)),
              ),
            ),
          );
        case receivesRoute:
          return _managePage(settings, builder: (_) => const ReceivePage());
        case receiveManageRoute:
          final args = settings.arguments as ReceiveManageArgument?;
          return _managePage(settings,
              builder: (_) => ReceiveManagePage(receiveId: args?.receiveId));
        case stockCountsRoute:
          return _managePage(settings, builder: (_) => const StockCountsPage());
        case stockCountManageRoute:
          final args = settings.arguments as StockCountManageArgument?;
          return _managePage(settings,
              builder: (_) =>
                  StockCountManagePage(stockCountId: args?.stockCountId));
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
          return RouterUm.generateRoute(
              const RouteSettings(name: routeSplash));
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
