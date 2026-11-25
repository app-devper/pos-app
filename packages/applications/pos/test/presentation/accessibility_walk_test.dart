// The accessibility walk: every screen and dialog the widget tests know how
// to build (the layout sweep's set, and a few more), on a phone and a
// desktop, in the app's Thai strings. Every control a finger or a pointer
// can tap must have a name a screen reader says — a label or a tooltip —
// and no two controls on one screen may have the same name.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:um/domain/usecase/auth_use_cases.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/home/main/cart_page.dart';
import 'package:pos/presentation/home/main/cart_view_model.dart';
import 'package:pos/presentation/home/main/cart_widget.dart';
import 'package:pos/presentation/order/detail/order_detail_page.dart';
import 'package:pos/presentation/order/detail/order_detail_view_model.dart';
import 'package:pos/presentation/product/main/product_stock_card.dart';
import 'package:pos/presentation/receive/main/receives_view_model.dart';
import 'package:pos/presentation/receive/main/receives_widget.dart';
import 'package:pos/presentation/receive/manage/receive_manage_page.dart';
import 'package:pos/presentation/receive/manage/receive_manage_view_model.dart';
import '../support/app_fonts.dart';
import '../support/app_languages.dart';
import '../support/main_screens.dart';
import 'home/main/cart_page_sale_test.dart' as cart;
import 'order/detail/order_detail_view_model_test.dart' as bill;
import 'receive/main/receives_view_model_test.dart' as receipts;
import 'receive/manage/receive_manage_view_model_test.dart' as receipt;

/// A screen and what to do on it once it is shown, before the walk.
typedef _Walked = ({Screen build, Future<void> Function(WidgetTester)? then});

Product _product(String id, String name) => Product(
      id: id,
      name: name,
      status: 'ACTIVE',
      category: 'General',
      createdDate: '',
      units: const [],
      prices: const [],
      stocks: const [],
    );

CartOrderItem _cartLine(String name) => CartOrderItem(
      title: name,
      quantity: 2,
      price: 25,
      unit: 'ชิ้น',
      discount: 0,
      priceDetail: 'ราคาหน้าร้าน',
      allowOversell: false,
      onRemove: () {},
      onAdd: () {},
      onEdit: () {},
      onEditPrice: () {},
      onToggleOversell: () {},
    );

OrderItemDetail _billLine(String id, String name) => OrderItemDetail(
      id: id,
      product: _product('p-$id', name),
      quantity: 2,
      price: 25,
      costPrice: 10,
      discount: 0,
      createdDate: '2026-11-26T10:00:00Z',
      order: null,
    );

OrderDetail _bill() => OrderDetail(
      id: 'order-1',
      createdDate: '2026-11-26T10:00:00Z',
      items: [_billLine('i1', 'พาราเซตามอล'), _billLine('i2', 'ยาแก้ไอ')],
      total: 100,
      totalCost: 40,
      discount: 0,
      type: 'Cash',
      code: 'OD_202611260001',
      customerCode: '',
      customerName: '',
    );

ProductStock _lot(String id, String lot) => ProductStock(
      id: id,
      unitId: 'u1',
      productId: 'p1',
      receiveCode: '',
      sequence: 1,
      lotNumber: lot,
      costPrice: 5,
      price: 10,
      import: 10,
      quantity: 10,
      expireDate: '2030-01-31T00:00:00Z',
      importDate: '2026-11-26T00:00:00Z',
    );

final _unit = ProductUnit(
  id: 'u1',
  productId: 'p1',
  costPrice: 5,
  unit: 'ชิ้น',
  size: 1,
  barcode: '',
  volume: 0,
  volumeUnit: '',
);

const _customer = 'สมชาย ใจดี';

/// Puts the sale fakes' product in the cart and chooses a customer.
Future<void> _fillCart(WidgetTester tester) async {
  final sale = sl<CartViewModel>();
  await tester.runAsync(() => sale.addOrderItem('111'));
  sale.setCustomer(Customer(
      id: 'c1',
      code: 'CU0001',
      name: _customer,
      address: '',
      phone: '',
      email: '',
      status: 'ACTIVE',
      type: 'General'));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _morePages = <String, _Walked>{
  'the selling screen with a line and a customer': (
    build: () {
      cart.registerSellingScreen('OD_202611260001');
      return const Scaffold(body: CartPage());
    },
    then: _fillCart,
  ),
  'two cart lines': (
    build: () => Scaffold(
          body: Column(children: [
            _cartLine('พาราเซตามอล'),
            _cartLine('ยาแก้ไอ'),
          ]),
        ),
    then: null,
  ),
  'the bill detail, for an admin': (
    build: () {
      sl.registerFactory(() => OrderDetailViewModel(
            getRoleUseCase:
                GetRoleUseCase(bill.FakeLoginRepository(role: 'ADMIN')),
            orderRepo: bill.FakeOrderRepository(orderDetail: _bill()),
            supplierRepo: bill.FakeSupplierRepository(
                supplier: Supplier(
                    id: 's1', name: 'ร้าน', address: '', phone: '', taxId: '')),
            customerRepo: bill.FakeCustomerRepository(),
          ));
      return const OrderDetailPage(orderId: 'order-1');
    },
    then: null,
  ),
  'the receipt list': (
    build: () {
      sl.registerFactory(() => ReceivesViewModel(
              receiveRepo: receipts.FakeReceiveRepository(receives: [
            receipts.buildReceive('1', 'RC-1'),
            receipts.buildReceive('2', 'RC-2'),
          ])));
      return Scaffold(body: ReceivesWidget(onSelected: (_) {}, onMenu: () {}));
    },
    then: null,
  ),
  'the receipt page': (
    build: () {
      sl.registerFactory<ProductRepository>(
          () => receipt.FakeProductRepository());
      sl.registerFactory(() => ReceiveManageViewModel(
            receiveRepo: receipt.FakeReceiveRepository(
                receive: receipt.buildReceive('r1'),
                items: [receipt.buildReceiveItem('r1')]),
            supplierRepo: receipt.FakeSupplierRepository(suppliers: [
              Supplier(
                  id: 's1', name: 'ACME', address: '', phone: '', taxId: '')
            ]),
            productRepo: receipt.FakeProductRepository(),
          ));
      return const ReceiveManagePage(receiveId: 'r1');
    },
    then: null,
  ),
  'a product stock card': (
    build: () => Scaffold(
          body: ProductStockCard(
            unit: _unit,
            stocks: [_lot('s1', 'L2026A'), _lot('s2', 'L2026B')],
            price: ProductPrice(
                id: 'pr1',
                unitId: 'u1',
                productId: 'p1',
                price: 10,
                customerType: 'General'),
            onSequence: () {},
            onAdd: () {},
            onEdit: (_) {},
            onQuantity: (_) {},
            onAdjust: (_) {},
          ),
        ),
    then: null,
  ),
};

/// The walk's whole set: the sweep's pages and dialogs, then the rest.
final _screens = <String, (_Walked, bool)>{
  for (final MapEntry(:key, :value) in mainPages.entries)
    key: ((build: value, then: null), false),
  for (final MapEntry(:key, :value) in mainDialogs.entries)
    key: ((build: value, then: null), true),
  for (final MapEntry(:key, :value) in _morePages.entries) key: (value, false),
};

/// A cart line does not fit a 360 px phone's cart (finding 29, pinned in
/// `cart_order_item_layout_test.dart`): the screen with a line is walked on
/// the emulator's phone size instead.
const _linePhoneSize = Size(411, 891);
const _needsLinePhone = {'the selling screen with a line and a customer'};

bool _isTappable(Widget widget) =>
    (widget is InkResponse && widget.onTap != null) ||
    (widget is GestureDetector && widget.onTap != null);

/// Widgets that say nothing about which control it is.
const _layoutWidgets = {
  'Row',
  'Column',
  'SizedBox',
  'Expanded',
  'Flexible',
  'Padding',
  'Container',
  'Center',
  'Align',
  'ListView',
  'Scaffold',
  'MaterialApp',
  'Tooltip',
  'ConstrainedBox',
  'Stack',
  'Positioned',
  'Card',
  'Builder',
  'Ink',
};

/// The names of the project's own widgets around [element], innermost
/// first, and the icon inside it: enough to find the control in the code.
String _describe(Element element) {
  final owners = <String>[];
  element.visitAncestorElements((ancestor) {
    final type = ancestor.widget.runtimeType.toString();
    if (debugIsLocalCreationLocation(ancestor.widget) &&
        !_layoutWidgets.contains(type)) {
      owners.add(type);
    }
    return owners.length < 3;
  });
  final icons = <String>[];
  void visit(Element child) {
    final widget = child.widget;
    if (widget is Icon && widget.icon != null) {
      icons.add('U+${widget.icon!.codePoint.toRadixString(16)}');
    }
    child.visitChildren(visit);
  }

  element.visitChildren(visit);
  return '${element.widget.runtimeType} ${icons.join(',')} in '
      '${owners.join(' < ')}';
}

/// What a screen reader says for a control: its label and its tooltip.
String _name(SemanticsData data) =>
    [data.label, data.tooltip].where((s) => s.trim().isNotEmpty).join(' | ');

/// Each tappable control's semantics node with the elements that make it.
Map<SemanticsNode, List<Element>> _controls(WidgetTester tester) {
  final controls = <SemanticsNode, List<Element>>{};
  for (final element in find.byWidgetPredicate(_isTappable).evaluate()) {
    final node =
        tester.getSemantics(find.byElementPredicate((e) => e == element));
    if (!node.getSemanticsData().hasAction(SemanticsAction.tap)) continue;
    controls.putIfAbsent(node, () => []).add(element);
  }
  return controls;
}

/// Every control with no name, and every name two controls share.
List<String> _faults(WidgetTester tester) {
  final controls = _controls(tester);
  final byName = <String, List<SemanticsNode>>{};
  final faults = <String>[];
  for (final MapEntry(key: node, value: elements) in controls.entries) {
    final name = _name(node.getSemanticsData());
    if (name.isEmpty) {
      faults.add('no name: ${_describe(elements.first)}');
    } else {
      byName.putIfAbsent(name, () => []).add(node);
    }
  }
  for (final MapEntry(key: name, value: nodes) in byName.entries) {
    if (nodes.length > 1) {
      faults.add('${nodes.length} controls named "$name": '
          '${nodes.map((n) => _describe(controls[n]!.first)).join('; ')}');
    }
  }
  return faults;
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  for (final size in [phoneSize, desktopSize]) {
    for (final MapEntry(key: name, value: (screen, isDialog))
        in _screens.entries) {
      testWidgets('every control on $name has its own name at $size',
          (tester) async {
        // Arrange
        final semantics = tester.ensureSemantics();
        useViewSize(
            tester,
            size == phoneSize && _needsLinePhone.contains(name)
                ? _linePhoneSize
                : size);
        await showScreen(tester, screen.build(),
            isDialog: isDialog, languages: thaiLanguages);
        await screen.then?.call(tester);

        // Act
        final faults = _faults(tester);

        // Assert
        expect(faults, isEmpty, reason: faults.join('\n'));
        semantics.dispose();
      });
    }
  }
}
