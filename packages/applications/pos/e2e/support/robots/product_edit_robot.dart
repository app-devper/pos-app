// A product's edit form (its name) and the detail's ราคา tab with its price
// dialog, on a wide screen. The detail and delete live in ProductRobot.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/title_bar.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/product/edit/product_edit_page.dart';
import 'package:pos/presentation/product/main/product_detail_widget.dart';
import 'package:pos/presentation/product/price/product_price_widget.dart';
import '../pump.dart';
import 'form_driver.dart';
import 'product_robot.dart';

final _detail = find.byType(ProductDetailWidget);
final _editPage = find.byType(ProductEditPage);
final _priceDialog = find.byType(ProductPriceWidget);

/// The dialog's centre is blank space, so it is never hit-testable itself;
/// its title bar is.
final _priceDialogTitle = find
    .descendant(of: _priceDialog, matching: find.byType(TitleBar))
    .hitTestable();

class ProductEditRobot {
  ProductEditRobot(this.products);

  final ProductRobot products;

  FormDriver get form => products.form;

  WidgetTester get tester => products.tester;

  /// The detail's title bar showing [name].
  Finder detailTitle(String name) => find
      .descendant(
          of: find.descendant(of: _detail, matching: find.byType(TitleBar)),
          matching: find.text(name))
      .hitTestable();

  /// From the detail: 'แก้ไข', types [name] into 'ชื่อสินค้า' and presses
  /// 'ยืนยัน'; returns once the detail shows [name].
  Future<void> rename(String name) async {
    await products.openEditForm();
    await form.enter('ชื่อสินค้า', name, within: _editPage);
    await products.shell.tapTitleBarAction('ยืนยัน');
    await tester.pump();
    await form.awaitOutcome(detailTitle(name));
  }

  // --- The ราคา tab -----------------------------------------------------------

  /// On the ราคา tab: [price] on the same card as the customer type
  /// [customerType] (the tab lists types in one column, prices in the
  /// next, row for row).
  Finder priceRow(String customerType, String price) {
    final index = _typesShown().indexOf(customerType);
    final prices = _pricesShown();
    if (index < 0 || index >= prices.length || prices[index] != price) {
      return find.byWidgetPredicate((_) => false,
          description: '$customerType at $price (tab shows '
              '${_typesShown()} at $prices)');
    }
    return priceTabShows(price);
  }

  /// [text] (exactly) on the ราคา tab.
  Finder priceTabShows(String text) =>
      find.descendant(of: _detail, matching: find.text(text)).hitTestable();

  List<String> _typesShown() =>
      _columnTexts('ผูกกับประเภทลูกค้า').where((t) => t != 'แก้ไข').toList();

  List<String> _pricesShown() => _columnTexts('ราคา');

  /// The texts under the column headed [heading], after the heading.
  List<String> _columnTexts(String heading) {
    final header = find.descendant(
        of: _detail,
        matching: find.byWidgetPredicate(
            (w) => w is Text && w.data == heading && w.style?.fontSize == 14));
    final column = find.ancestor(of: header, matching: find.byType(Column));
    if (column.evaluate().isEmpty) return const [];
    return find
        .descendant(of: column.first, matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .skip(1)
        .toList();
  }

  /// The 'แก้ไข' next to [customerType] opens its price; types [price] and
  /// confirms.
  Future<void> changePrice(String customerType, double price) async {
    // The Row that holds the type's Text itself, then its 'แก้ไข'.
    final row = find.descendant(
        of: _detail,
        matching: find.byWidgetPredicate((w) =>
            w is Row &&
            w.children.any((c) => c is Text && c.data == customerType)));
    await tester.tap(
        find.descendant(of: row, matching: find.text('แก้ไข')).hitTestable());
    await _fillPriceDialog(price);
  }

  /// 'เพิ่มราคาขาย', picks [customerType] and types [price].
  Future<void> addPrice(String customerType, double price) async {
    await tester.tap(priceTabShows('เพิ่มราคาขาย'));
    await tester.pump();
    await pumpUntilFound(tester, _priceDialogTitle);
    await form.choose('ผูกกับประเภทลูกค้า', customerType, within: _priceDialog);
    await _fillPriceDialog(price);
  }

  Future<void> _fillPriceDialog(double price) async {
    await tester.pump();
    await pumpUntilFound(tester, _priceDialogTitle);
    await form.enter('ราคาขายต่อหน่วย', _number(price), within: _priceDialog);
    await products.shell.tapTitleBarAction('ยืนยัน');
    await form.awaitClosed(_priceDialog);
    // The detail reloads the product once the dialog has closed.
    await pumpUntilFound(tester, priceTabShows('฿${price.toStringAsFixed(2)}'));
  }

  static String _number(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
