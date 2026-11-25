// The "สินค้า" area on a wide screen: the product list on the left, and on
// the right the menu, the add form, or a product's detail with its tabs and
// the stock adjustment dialog.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/widgets/loading_dialog.dart';
import 'package:design_system/widgets/title_bar.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/product/edit/product_edit_page.dart';
import 'package:pos/presentation/product/history/product_history_widget.dart';
import 'package:pos/presentation/product/main/product_detail_widget.dart';
import 'package:pos/presentation/product/main/products_widget.dart';
import 'package:pos/presentation/product/stock/stock_adjustment_history_widget.dart';
import 'package:pos/presentation/product/stock/stock_adjustment_widget.dart';
import '../pump.dart';
import '../stock_plan.dart';
import 'form_driver.dart';
import 'shell_robot.dart';

const _addMenuItem = 'เพิ่มสินค้า';
const _searchHint = 'ค้นหาสิ่งที่คุณต้องการ...';
const _activeStatus = 'แสดงหน้าร้าน';

/// The list re-reads the catalogue after a stock change; give it time.
const _stockTimeout = Duration(seconds: 20);

final _list = find.byType(ProductsWidget);
final _detail = find.byType(ProductDetailWidget);
final _adjustDialog = find.byType(StockAdjustmentWidget);
final _menu = find.widgetWithText(ListTile, _addMenuItem).hitTestable();

/// What the add form is filled in with.
class NewProduct {
  const NewProduct({
    required this.name,
    required this.barcode,
    required this.unit,
    required this.price,
    required this.cost,
  });

  final String name;
  final String barcode;
  final String unit;
  final double price;
  final double cost;
}

class ProductRobot {
  ProductRobot(this.shell) : form = FormDriver(shell);

  final ShellRobot shell;
  final FormDriver form;

  WidgetTester get tester => shell.tester;

  // --- The list -------------------------------------------------------------

  /// From anywhere in the shell: the sidebar's สินค้า, until the list has
  /// loaded without an error.
  Future<void> openList() async {
    await shell.openProducts();
    await shell.expectScreenWithoutError(_menu);
    await pumpUntilGone(tester,
        find.descendant(of: _list, matching: find.byType(ProgressIndicator)));
    expect(find.text('ลองอีกครั้ง'), findsNothing,
        reason: 'the product list failed to load');
  }

  /// The list row titled exactly [name].
  Finder _row(String name) => find
      .descendant(
          of: _list,
          matching: find.byWidgetPredicate((w) =>
              w is ListTile &&
              w.title is Text &&
              (w.title as Text).data == name))
      .hitTestable();

  /// Types [name] into the list's search box, the way a user narrows a long
  /// catalogue down.
  Future<void> _search(String name) async {
    await tester.enterText(shell.searchField(_searchHint), name);
    await tester.pump();
  }

  /// Whether the list shows [name] once searched for.
  Future<bool> isListed(String name) async {
    await _search(name);
    return _row(name).evaluate().isNotEmpty;
  }

  /// Opens [name]'s detail from the list.
  Future<void> open(String name) async {
    expect(await isListed(name), isTrue, reason: '$name is not listed');
    await tester.tap(_row(name));
    await tester.pump();
    await form.awaitOutcome(
        find.descendant(of: find.byType(TitleBar), matching: find.text(name)));
  }

  // --- Stock on hand in the list ----------------------------------------------

  /// The on-hand figure the list shows for [name] with its sort toggle on
  /// (`คงเหลือ <q> <unit>`): the sum of the signed-in Branch's lots; null if
  /// the row does not show one.
  Future<int?> stockOnHand(String name) async {
    await _showOnHand(name);
    return onHandIn(_subtitleOf(name) ?? '');
  }

  /// Waits until the list shows [expected] on hand for [name]; the list
  /// re-reads the catalogue on its own after a stock change, as a user sees
  /// it. Fails with what it shows instead.
  Future<void> expectStockOnHand(String name, int expected,
      {required String unit}) async {
    await _showOnHand(name);
    final wanted = 'คงเหลือ $expected $unit';
    final clock = Stopwatch()..start();
    while (_subtitleOf(name) != wanted) {
      if (clock.elapsed > _stockTimeout) {
        fail('$name: the list shows "${_subtitleOf(name)}", not "$wanted"');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Searches for [name] and turns the sort-by-stock toggle on (the
  /// subtitle shows only the unit while it is off).
  Future<void> _showOnHand(String name) async {
    expect(await isListed(name), isTrue, reason: '$name is not listed');
    final sortOff =
        find.descendant(of: _list, matching: find.byIcon(Icons.balance));
    if (sortOff.hitTestable().evaluate().isEmpty) return;
    await tester.tap(sortOff.hitTestable());
    await tester.pump();
    await pumpUntilFound(
        tester, find.descendant(of: _list, matching: find.byIcon(Icons.sort)));
  }

  String? _subtitleOf(String name) {
    final row = _row(name).evaluate().firstOrNull;
    final subtitle = (row?.widget as ListTile?)?.subtitle;
    return subtitle is Text ? subtitle.data : null;
  }

  // --- Add ------------------------------------------------------------------

  /// The add form's title; its action button has the same text, so the
  /// title is told apart as plain Text in the top TitleBar.
  Finder get addFormTitle => find
      .descendant(
          of: find.byType(TitleBar).hitTestable().last,
          matching: find.byWidgetPredicate(
              (w) => w is Text && w.data == _addMenuItem && !_inButton(w)))
      .hitTestable();

  bool _inButton(Text text) => find
      .ancestor(of: find.byWidget(text), matching: find.byType(TextButton))
      .evaluate()
      .isNotEmpty;

  Future<void> openAddForm() async {
    await tester.tap(_menu);
    await tester.pump();
    await pumpUntilFound(tester, form.field('ชื่อสินค้า'));
  }

  /// Fills the add form; the status is set to show the product in the shop
  /// (the form starts with none, and selling lists only shown products).
  Future<void> fillAddForm(NewProduct product) async {
    await form.enter('ชื่อสินค้า', product.name);
    await form.choose('การแสดงข้อมูลสินค้า', _activeStatus);
    await form.enter('ชื่อหน่วยนับ', product.unit);
    await form.enter('ราคาขายต่อหน่วย (ค่าเริ่มต้น)', _number(product.price));
    await form.enter('ราคาทุนต่อหน่วย (ค่าเริ่มต้น)', _number(product.cost));
    await form.enter('บาร์โค้ด', product.barcode);
  }

  /// Presses the add form's action, which is also labelled 'เพิ่มสินค้า'.
  Future<void> submitAddForm() async {
    await shell.tapTitleBarAction(_addMenuItem);
    await tester.pump();
  }

  /// Waits for the menu to come back, as it does once the product is saved.
  Future<void> awaitAdded() => form.awaitOutcome(_menu);

  Future<void> add(NewProduct product) async {
    await openAddForm();
    await fillAddForm(product);
    await submitAddForm();
    await awaitAdded();
  }

  Finder fieldError(String label, String error) =>
      form.fieldError(label, error);

  static String _number(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  // --- Detail ---------------------------------------------------------------

  /// Opens the detail tab [label].
  Future<void> openTab(String label) async {
    final tab =
        find.descendant(of: find.byType(TabBar), matching: find.text(label));
    await tester.tap(tab.hitTestable());
    await tester.pump();
    // The tab's page slides in; wait until its content takes taps.
    await pumpUntil(tester, () => !_tabMoving(), 'the $label tab to settle');
    await shell.expectScreenWithoutError(tab);
  }

  bool _tabMoving() {
    final bar = find.byType(TabBar).evaluate().firstOrNull;
    final controller = (bar?.widget as TabBar?)?.controller;
    if (controller == null) return false;
    return controller.indexIsChanging ||
        (controller.animation?.isAnimating ?? false);
  }

  /// The stock tab's total for the unit: `คงเหลือรวมทั้งหมด: <q> <unit>`.
  Finder stockTotal(int quantity, String unit) =>
      _inDetail(find.text('คงเหลือรวมทั้งหมด: $quantity $unit'));

  /// A stock row whose expiry the tab shows as [shortDate] (d/M/yy).
  Finder stockRowExpiring(String shortDate) => _inDetail(find.text(shortDate));

  /// A history entry whose description is [description] (pos-api may end
  /// it with a unit).
  Finder historyRow(String description) => find
      .descendant(
          of: find.byType(ProductHistoryWidget),
          matching: find.byWidgetPredicate((w) =>
              w is Text &&
              (w.data == description ||
                  (w.data?.startsWith('$description ') ?? false))))
      .hitTestable();

  /// On the ปรับสต็อก tab: an adjustment card's note.
  Finder adjustmentNote(String note) => _inAdjustments(find.text(note));

  /// On the ปรับสต็อก tab: an adjustment card's change, e.g. `+2` or `-2`.
  Finder adjustmentDelta(String delta) => _inAdjustments(find.text(delta));

  Finder _inAdjustments(Finder finder) => find
      .descendant(
          of: find.byType(StockAdjustmentHistoryWidget), matching: finder)
      .hitTestable();

  Finder textOnScreen(String text) => find.text(text).hitTestable();

  Finder _inDetail(Finder finder) =>
      find.descendant(of: _detail, matching: finder).hitTestable();

  // --- Stock adjustment -----------------------------------------------------

  /// From the stock tab: the row's 'ปรับสต็อก', checks the dialog names
  /// [lot] holding [onHand], then adds or takes [quantity] for [reason] and
  /// confirms. The product's only lot is adjusted; it fails if there are
  /// several, since the tab does not say which row is which lot.
  Future<void> adjust({
    required String lot,
    required int onHand,
    required bool increase,
    required int quantity,
    String note = '',
    String reason = 'อื่นๆ',
  }) async {
    final tune = _inDetail(find.byTooltip('ปรับสต็อก'));
    expect(tune, findsOneWidget, reason: 'expected one lot on the stock tab');
    await tester.tap(tune);
    await tester.pump();
    await pumpUntilFound(tester, _adjustDialog.hitTestable());
    expect(_inAdjust(find.text('ล็อต $lot คงเหลือ $onHand')), findsOneWidget);

    await form.choose('เหตุผลการปรับสต็อก', reason, within: _adjustDialog);
    await tester.tap(_inAdjust(find.text(increase ? 'เพิ่มสต็อก' : 'ลดสต็อก')));
    await tester.pump();
    await form.enter('จำนวน', '$quantity', within: _adjustDialog);
    await form.enter('หมายเหตุ', note, within: _adjustDialog);
    await shell.tapTitleBarAction('ยืนยัน');
    await form.awaitClosed(_adjustDialog);
    await shell.expectScreenWithoutError(_detail);
  }

  Finder _inAdjust(Finder finder) =>
      find.descendant(of: _adjustDialog, matching: finder).hitTestable();

  // --- Edit and delete --------------------------------------------------------

  /// From the detail: its 'แก้ไข', until the edit form has filled itself in.
  /// It opens with the name already shown, then reloads the product behind
  /// a loading dialog and overwrites its fields; only that reload sets the
  /// status dropdown (product_edit_page.dart _onLoaded), so the suite's
  /// products' status showing is the sign it is done. Typing earlier would
  /// be lost, and saving would send no status.
  Future<void> openEditForm() async {
    await shell.tapTitleBarAction('แก้ไข');
    await pumpUntilFound(tester, _editPage.hitTestable());
    await pumpUntilFound(
        tester,
        find.descendant(
            of: form.dropdown('การแสดงข้อมูลสินค้า', within: _editPage),
            matching: find.text(_activeStatus)));
    await pumpUntilGone(tester, find.byType(LoadingDialog));
  }

  /// From the detail: 'แก้ไข' → the red 'ลบสินค้า' → confirm
  /// 'ต้องการลบสินค้าใช่หรือไม่'; returns once the menu is back.
  Future<void> delete() async {
    await openEditForm();
    final remove =
        find.descendant(of: _editPage, matching: find.text('ลบสินค้า'));
    // It is the last thing on a long form.
    await tester.ensureVisible(remove);
    await tester.pump();
    await tester.tap(remove.hitTestable());
    await tester.pump();
    await pumpUntilFound(
        tester, find.text('ต้องการลบสินค้าใช่หรือไม่').hitTestable());
    await shell.confirm();
    await form.awaitOutcome(_menu);
  }
}

final _editPage = find.byType(ProductEditPage);
