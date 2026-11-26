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
import 'package:pos/presentation/core/readable_tile.dart';
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
import '../support/manage_screens.dart';
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

CartOrderItem _cartLine(String name, {String unit = 'ชิ้น'}) => CartOrderItem(
      title: name,
      quantity: 2,
      price: 25,
      unit: unit,
      discount: 0,
      priceDetail: 'ราคาหน้าร้าน',
      allowOversell: false,
      onRemove: () {},
      onAdd: () {},
      onEdit: () {},
      onEditPrice: () {},
      onToggleOversell: () {},
    );

OrderItemDetail _billLine(String id, String name, {int quantity = 2}) =>
    OrderItemDetail(
      id: id,
      product: _product('p-$id', name),
      quantity: quantity,
      price: 25,
      costPrice: 10,
      discount: 0,
      createdDate: '2026-11-26T10:00:00Z',
      order: null,
    );

OrderDetail _bill({List<OrderItemDetail>? items}) => OrderDetail(
      id: 'order-1',
      createdDate: '2026-11-26T10:00:00Z',
      items:
          items ?? [_billLine('i1', 'พาราเซตามอล'), _billLine('i2', 'ยาแก้ไอ')],
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

/// The bill detail of [detail], as an admin sees it.
Widget _billDetail(OrderDetail detail) {
  sl.registerFactory(() => OrderDetailViewModel(
        getRoleUseCase: GetRoleUseCase(bill.FakeLoginRepository(role: 'ADMIN')),
        orderRepo: bill.FakeOrderRepository(orderDetail: detail),
        supplierRepo: bill.FakeSupplierRepository(
            supplier: Supplier(
                id: 's1', name: 'ร้าน', address: '', phone: '', taxId: '')),
        customerRepo: bill.FakeCustomerRepository(),
      ));
  return const OrderDetailPage(orderId: 'order-1');
}

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
  // One product sold in two units: a line per unit, each named apart.
  'one product in two units in the cart': (
    build: () => Scaffold(
          body: Column(children: [
            _cartLine('พาราเซตามอล'),
            _cartLine('พาราเซตามอล', unit: 'แผง'),
          ]),
        ),
    then: null,
  ),
  'a bill with one product on two lines, for an admin': (
    build: () => _billDetail(_bill(items: [
          _billLine('i1', 'พาราเซตามอล'),
          _billLine('i2', 'พาราเซตามอล', quantity: 1),
        ])),
    then: null,
  ),
  'the bill detail, for an admin': (
    build: () => _billDetail(_bill()),
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
  for (final MapEntry(:key, :value) in manageScreens.entries)
    key: ((build: value, then: null), false),
};

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

/// A tappable a screen reader is not meant to reach: [ReadableTile]'s row
/// tap, which its label node offers instead, the framework's own gesture
/// detectors, and showCenterDialog's tap catchers.
bool _isAllowedUnreachable(Element element) {
  // The framework's own gesture detectors (an InkResponse's, a selection
  // handle's): their control, if any, is the widget around them.
  if (element.widget is GestureDetector &&
      !debugIsLocalCreationLocation(element.widget)) {
    return true;
  }
  var allowed = false;
  var depth = 0;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is ReadableTile) {
      allowed = element.widget is InkWell &&
          (element.widget as InkWell).excludeFromSemantics;
      return false;
    }

    // showCenterDialog's pair of tap catchers (outside closes, the dialog
    // swallows taps); the route's barrier offers the dismiss.
    if (_isTapCatcher(element.widget) &&
        (_isTapCatcher(widget) || _holdsTapCatcher(element))) {
      allowed = true;
      return false;
    }
    return ++depth < 12;
  });
  return allowed;
}

bool _isTapCatcher(Widget widget) =>
    widget is GestureDetector && widget.excludeFromSemantics;

/// Whether a tap catcher sits just under [element] (the outer of the pair).
bool _holdsTapCatcher(Element element) {
  var found = false;
  void visit(Element child, int depth) {
    if (found || depth > 4) return;
    if (_isTapCatcher(child.widget)) {
      found = true;
      return;
    }
    child.visitChildren((c) => visit(c, depth + 1));
  }

  element.visitChildren((c) => visit(c, 1));
  return found;
}

/// Whether [element] is drawn: not under an Offstage, and of some size.
bool _isVisible(Element element) {
  final box = element.renderObject;
  if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return false;
  var offstage = false;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is Offstage && (ancestor.widget as Offstage).offstage) {
      offstage = true;
      return false;
    }
    return true;
  });
  return !offstage;
}

/// Each tappable control's semantics node with the elements that make it,
/// and the faults found on the way: a visible control whose node offers no
/// tap (kept out of the semantics, or under ExcludeSemantics).
(Map<SemanticsNode, List<Element>>, List<String>) _controls(
    WidgetTester tester) {
  final controls = <SemanticsNode, List<Element>>{};
  final faults = <String>[];
  for (final element in find.byWidgetPredicate(_isTappable).evaluate()) {
    if (!_isVisible(element) || _isAllowedUnreachable(element)) continue;
    final node =
        tester.getSemantics(find.byElementPredicate((e) => e == element));
    if (!node.getSemanticsData().hasAction(SemanticsAction.tap)) {
      faults.add('not offered to a screen reader: ${_describe(element)}');
      continue;
    }
    controls.putIfAbsent(node, () => []).add(element);
  }
  return (controls, faults);
}

/// Whether [elements], all in one node, are one control: two tappables in
/// one node are two controls a screen reader hears as one (an unnamed icon
/// merged into its row, read by the row's name).
/// A framework control's own parts (a CheckboxListTile's tile and box) are
/// one control: only a tappable the project put there counts as a second.
bool _isOneControl(List<Element> elements) =>
    elements.length < 2 ||
    !elements.skip(1).any((e) => debugIsLocalCreationLocation(e.widget));

/// The texts a control holds itself: its texts and icon labels, and the
/// label or tooltip of the widgets right around it.
Set<String> _ownTexts(Element element) {
  final texts = <String>{};
  void add(String? text) {
    if (text != null && text.trim().isNotEmpty) texts.add(text.trim());
  }

  void read(Widget widget) {
    switch (widget) {
      case Text(:final data, :final semanticsLabel):
        add(data);
        add(semanticsLabel);
      case Icon(:final semanticLabel):
        add(semanticLabel);
      case Semantics(:final properties):
        add(properties.label);
        add(properties.tooltip);
      case Tooltip(:final message):
        add(message);
      case RichText(:final text):
        add(text.toPlainText());
    }
  }

  void visit(Element child) {
    read(child.widget);
    child.visitChildren(visit);
  }

  visit(element);
  var depth = 0;
  element.visitAncestorElements((ancestor) {
    read(ancestor.widget);
    return ++depth < 12;
  });
  return texts;
}

/// Whether the name a screen reader says for [element] is none of its
/// own: an unnamed icon merged into its row and read by the row's text.
bool _isNamedByItsRow(Element element, String name) =>
    !_ownTexts(element).any(name.contains);

/// Text that is the widget tests' own data, not the app's strings.
const _testData = [
  'open', // dialogOpener's button
  'Paracetamol',
  'ACME',
  'name-',
  'Product p',
  'COUNT-1',
  'RC-',
  'OD_',
  'CU0001',
  'L2026',
  'LOT-1',
];

/// Whether [name] is in English only (no Thai), and not test data.
bool _isEnglishOnly(String name) =>
    !RegExp(r'[\u0E00-\u0E7F]').hasMatch(name) &&
    RegExp(r'[A-Za-z]').hasMatch(name) &&
    !_testData
        .any((data) => data == 'open' ? name == data : name.contains(data));

/// Every control with no name, a name in English only, a control merged
/// into another's node or kept from a screen reader, and every name two
/// controls share.
List<String> _faults(WidgetTester tester) {
  final (controls, faults) = _controls(tester);
  final byName = <String, List<SemanticsNode>>{};
  for (final MapEntry(key: node, value: elements) in controls.entries) {
    final name = _name(node.getSemanticsData());
    if (name.isNotEmpty && _isNamedByItsRow(elements.first, name)) {
      faults.add('merged, read by its row\'s text "$name": '
          '${_describe(elements.first)}');
      continue;
    }
    if (!_isOneControl(elements)) {
      faults.add('merged into one node: '
          '${elements.map(_describe).join('; ')}');
    }
    if (name.isEmpty) {
      faults.add('no name: ${_describe(elements.first)}');
    } else if (_isEnglishOnly(name)) {
      faults.add('English only: "$name": ${_describe(elements.first)}');
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

/// Controls a screen reader cannot use, planted to prove the walk sees
/// each kind: a tap kept out of the semantics, a button under
/// ExcludeSemantics, an unnamed icon merged into its row's node, and a name
/// in English only.
class _PlantedOffenders extends StatelessWidget {
  const _PlantedOffenders();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          InkWell(
            excludeFromSemantics: true,
            onTap: () {},
            child: const Icon(Icons.star),
          ),
          ExcludeSemantics(
            child: IconButton(
                tooltip: 'ซ่อนอยู่',
                onPressed: () {},
                icon: const Icon(Icons.home)),
          ),
          ListTile(
            title: const Text('แถว'),
            onTap: () {},
            trailing:
                GestureDetector(onTap: () {}, child: const Icon(Icons.close)),
          ),
          IconButton(
              tooltip: 'Delete',
              onPressed: () {},
              icon: const Icon(Icons.delete)),
        ]),
      );
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  testWidgets('the walk finds every kind of planted offender', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    await showScreen(tester, const _PlantedOffenders(),
        isDialog: false, languages: thaiLanguages);

    // Act
    final faults = _faults(tester);

    // Assert
    String kinds(String kind) =>
        faults.where((f) => f.startsWith(kind)).join('\n');
    expect(kinds('not offered').split('\n'), hasLength(2),
        reason: faults.join('\n'));
    expect(kinds('merged'), isNotEmpty, reason: faults.join('\n'));
    expect(kinds('English only: "Delete"'), isNotEmpty,
        reason: faults.join('\n'));
    semantics.dispose();
  });

  for (final size in [phoneSize, desktopSize]) {
    for (final tab in productDetailTabs) {
      testWidgets(
          'every control on the product detail\'s $tab tab has its '
          'own name at $size', (tester) async {
        // Arrange
        final semantics = tester.ensureSemantics();
        useViewSize(tester, size);
        await showScreen(tester, productDetail(),
            isDialog: false, languages: thaiLanguages);
        await tester.tap(find.bySemanticsIdentifier(tab));
        await tester.pumpAndSettle();

        // Act
        final faults = _faults(tester);

        // Assert
        expect(faults, isEmpty, reason: faults.join('\n'));
        semantics.dispose();
      });
    }
  }

  for (final size in [phoneSize, desktopSize]) {
    for (final MapEntry(key: name, value: (screen, isDialog))
        in _screens.entries) {
      testWidgets('every control on $name has its own name at $size',
          (tester) async {
        // Arrange
        final semantics = tester.ensureSemantics();
        useViewSize(tester, size);
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
