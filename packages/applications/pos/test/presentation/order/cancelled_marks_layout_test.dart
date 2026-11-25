// The cancelled-bill marks and the bill code, laid out in the app's fonts on
// a 360 px phone with a long customer name and a 15-character bill code.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/order.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/order/order_summary.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/presentation/order/detail/order_detail_header.dart';
import 'package:pos/presentation/order/detail/order_line_tile.dart';
import 'package:pos/presentation/order/history/order_history_tile.dart';
import 'package:pos/presentation/order/main/order_list_tile.dart';
import '../../support/app_fonts.dart';
import '../../support/app_languages.dart';

const _code = 'OD_202611260123';
const _customer = 'บริษัท สุขภาพดี เภสัชภัณฑ์ และเวชภัณฑ์ (ประเทศไทย) จำกัด';
const _cancelled = 'CANCELLED';

final _product = Product(
  id: 'p1',
  name: 'พาราเซตามอล 500 มก. ชนิดเม็ด แผงละ 10 เม็ด กล่องละ 10 แผง',
  status: 'ACTIVE',
  category: 'General',
  createdDate: '',
  units: const [],
  prices: const [],
  stocks: const [],
);

final _order = Order(
  id: 'o1',
  code: _code,
  customerCode: 'C0001',
  customerName: _customer,
  createdDate: '2026-11-26T10:00:00Z',
  total: 123456.75,
  totalCost: 98765.5,
  discount: 0,
  type: 'Cash',
);

final _line = OrderItemDetail(
  id: 'i1',
  product: _product,
  quantity: 120,
  price: 1028.81,
  costPrice: 98765.5,
  discount: 0,
  createdDate: '2026-11-26T10:00:00Z',
  order: _order,
  status: _cancelled,
  returnedQty: 12,
);

final _summary = OrderSummary(
  id: 'o1',
  code: _code,
  customerCode: 'C0001',
  customerName: _customer,
  createdDate: '2026-11-26T10:00:00Z',
  total: 123456.75,
  totalCost: 98765.5,
  discount: 0,
  type: 'Store',
  status: _cancelled,
);

final _bill = OrderDetail(
  id: 'o1',
  createdDate: '2026-11-26T10:00:00Z',
  items: [_line],
  total: 123456.75,
  totalCost: 98765.5,
  discount: 0,
  type: 'Cash',
  code: _code,
  customerCode: 'C0001',
  customerName: _customer,
  status: _cancelled,
);

final _widgets = <String, Widget Function()>{
  'the bills list row': () =>
      OrderListTile(index: 0, order: _summary, showCost: true, onTap: () {}),
  'the bill line': () => OrderLineTile(
        line: _line,
        isAdmin: true,
        onTap: () {},
        onDelete: () {},
        onHistory: () {},
        onReturn: () {},
      ),
  'the bill detail header': () => Row(children: [
        Expanded(child: OrderDetailHeader(bill: _bill)),
        OrderDetailActions(
          bill: _bill,
          isAdmin: true,
          onPrint: () {},
          onSync: () {},
          onReturns: () {},
          onDelete: () {},
        ),
      ]),
  'the product sales history row': () =>
      OrderHistoryTile(line: _line, showCost: true),
};

/// A phone's touch density and the desktop's compact one.
final _densities =
    TargetPlatformVariant(const {TargetPlatform.android, TargetPlatform.macOS});

void main() {
  setUpAll(loadAppFonts);

  for (final MapEntry(key: name, value: build) in _widgets.entries) {
    testWidgets('$name of a cancelled bill fits a 360 px phone',
        (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);

      // Act
      await tester.pumpWidget(MaterialApp(
        theme: CustomTheme.mainTheme,
        localizationsDelegates: const [thaiLanguages],
        home: Scaffold(body: ListView(children: [build()])),
      ));

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.text('ยกเลิกแล้ว'), findsWidgets);
    }, variant: _densities);
  }

  testWidgets('the bills list row shows the whole bill code above its time',
      (tester) async {
    // Arrange
    useViewSize(tester, phoneSize);

    // Act
    await tester.pumpWidget(MaterialApp(
      theme: CustomTheme.mainTheme,
      localizationsDelegates: const [thaiLanguages],
      home: Scaffold(body: ListView(children: [_widgets.values.first()])),
    ));

    // Assert
    final code = tester.renderObject<RenderParagraph>(find.text(_code));
    expect(code.didExceedMaxLines, isFalse);
    expectInside(tester, find.text(_code), find.byType(ListTile));
  }, variant: _densities);
}
