// Text beside a control is readable on the web: a row's texts are one node
// of their own, with no children, so Flutter web writes them into the page
// as text (a node with children only gets an aria-label, which Maestro
// cannot read and which ARIA does not allow on a plain group). The row's
// buttons are separate nodes beside it.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/home/main/cart_page.dart';
import 'package:pos/presentation/home/main/cart_widget.dart';
import 'package:pos/presentation/order/detail/order_line_tile.dart';
import 'package:pos/presentation/receive/manage/receive_line_tile.dart';
import 'package:pos/domain/model/receive/receive_item.dart';
import '../support/app_fonts.dart';
import '../support/app_languages.dart';
import 'home/main/cart_page_sale_test.dart' as cart;

const _product = 'Paracetamol 500';

Widget _host(Widget child) => MaterialApp(
      theme: CustomTheme.mainTheme,
      localizationsDelegates: const [thaiLanguages],
      home: Scaffold(body: child),
    );

CartOrderItem _cartLine() => CartOrderItem(
      title: _product,
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

OrderItemDetail _billLine() => OrderItemDetail(
      id: 'i1',
      product: Product(
        id: 'p1',
        name: _product,
        status: 'ACTIVE',
        category: 'General',
        createdDate: '',
        units: const [],
        prices: const [],
        stocks: const [],
      ),
      quantity: 2,
      price: 40,
      costPrice: 16,
      discount: 0,
      createdDate: '2026-11-26T10:00:00Z',
      order: null,
    );

/// The one node labelled exactly [label].
SemanticsNode _node(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(label));

bool _isInside(SemanticsNode node, SemanticsNode ancestor) {
  for (var parent = node.parent; parent != null; parent = parent.parent) {
    if (parent == ancestor) return true;
  }
  return false;
}

/// Every node's label and tooltip, joined as a screen reader says them.
List<String> _spoken(WidgetTester tester) {
  final spoken = <String>[];
  bool visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    final said = [data.label, data.tooltip].where((s) => s.isNotEmpty);
    if (said.isNotEmpty) spoken.add(said.join(' | '));
    node.visitChildren(visit);
    return true;
  }

  var root = tester.getSemantics(find.byType(Scaffold));
  for (var up = root.parent; up != null; up = up.parent) {
    root = up;
  }
  visit(root);
  return spoken;
}

/// [text] is a leaf node, and each of [buttons] a node outside it.
void _expectRowNode(WidgetTester tester, String text, List<String> buttons) {
  final row = _node(tester, text);
  expect(row.childrenCount, 0, reason: '"$text" must be a node of its own');
  for (final button in buttons) {
    final node = tester.getSemantics(find.bySemanticsLabel(button));
    expect(_isInside(node, row), isFalse, reason: '$button is beside it');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  }
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  testWidgets('a cart line reads as one node: quantity, product and amount',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(_host(_cartLine()));

    // Assert
    expect(find.text('2x'), findsOneWidget);
    _expectRowNode(tester, '2x $_product ชิ้น ฿50.00 ราคาหน้าร้าน', [
      'ลดจำนวน $_product ชิ้น',
      'แก้ไขจำนวน $_product ชิ้น',
      'เพิ่มจำนวน $_product ชิ้น',
    ]);
    semantics.dispose();
  });

  testWidgets('a screen reader hears a cart line product as text once',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(_host(_cartLine()));

    // Assert: the line's text, then only its buttons, which say what they
    // do to it
    expect(_spoken(tester).where((s) => s.contains(_product)), [
      '2x $_product ชิ้น ฿50.00 ราคาหน้าร้าน',
      'อนุญาตขายเกินสต็อก $_product ชิ้น',
      'ลดจำนวน $_product ชิ้น',
      'แก้ไขจำนวน $_product ชิ้น',
      'เพิ่มจำนวน $_product ชิ้น',
    ]);
    semantics.dispose();
  });

  testWidgets('the chosen customer reads as one node beside its remove button',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    final customer = Customer(
        id: 'c1',
        code: 'CU0001',
        name: 'สมชาย ใจดี',
        address: '',
        phone: '',
        email: '',
        status: 'ACTIVE',
        type: 'General');

    // Act
    await tester.pumpWidget(_host(CartCustomerTile(
        customer: customer, onChoose: () {}, onRemove: () {})));

    // Assert
    _expectRowNode(tester, 'สมชาย ใจดี\nCU0001', []);
    final remove =
        tester.getSemantics(find.byTooltip('นำลูกค้า สมชาย ใจดี ออก'));
    expect(_isInside(remove, _node(tester, 'สมชาย ใจดี\nCU0001')), isFalse);
    semantics.dispose();
  });

  testWidgets('a bill line reads as one node: quantity, product and amount',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(_host(OrderLineTile(
      line: _billLine(),
      isAdmin: true,
      onTap: () {},
      onDelete: () {},
      onHistory: () {},
      onReturn: () {},
    )));

    // Assert
    _expectRowNode(tester, '2 $_product ต้นทุน: 16.00  กำไร: 24.00 40.00', [
      'ลบรายการ 2x $_product ฿40.00',
      'ประวัติการขาย 2x $_product ฿40.00',
      'คืนสินค้า 2x $_product ฿40.00',
    ]);
    semantics.dispose();
  });

  testWidgets('the cart title is a header of its own', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    useViewSize(tester, desktopSize);
    cart.registerSellingScreen('OD_202611260001');

    // Act
    await tester.pumpWidget(_host(const CartPage()));
    await tester.pump(const Duration(milliseconds: 100));

    // Assert
    final title = _node(tester, 'ตะกร้าสินค้า #1');
    expect(title.childrenCount, 0);
    expect(title.getSemanticsData().flagsCollection.isHeader, isTrue);
    semantics.dispose();
  });

  testWidgets('a receipt line reads as one node beside its delete button',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    final line = ReceiveItem(
        id: 'i1',
        receiveId: 'r1',
        productId: 'p1',
        lotId: 'l1',
        costPrice: 10,
        quantity: 2,
        product: _billLine().product);

    // Act
    await tester.pumpWidget(
        _host(ReceiveLineTile(line: line, imported: false, onDelete: () {})));

    // Assert
    _expectRowNode(tester, 'Name: $_product\nQuantity: 2 Cost: 10.00\n20.00',
        ['ลบรายการ $_product']);
    semantics.dispose();
  });
}
