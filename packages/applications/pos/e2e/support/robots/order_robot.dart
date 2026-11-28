// "รายการขาย": today's bill list (admin: the All / Store / Online chips) and
// a bill's detail, with its return dialog, returns history, and the deletes
// that cancel a line or the whole bill.

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/title_bar.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/order/detail/order_detail_page.dart';
import 'package:pos/presentation/order/main/order_page.dart';
import 'package:pos/presentation/order/return/product_return_widget.dart';
import 'package:pos/presentation/order/return/product_returns_history_widget.dart';
import '../api/order_api.dart';
import '../pump.dart';
import 'form_driver.dart';
import 'scroll.dart';
import 'shell_robot.dart';
import 'package:pos/presentation/order/detail/order_line_tile.dart';

/// One drag of the list; a few rows.
const _step = Duration(milliseconds: 100);

/// A reload shows nothing when it starts, so the list counts as reloaded
/// once its rows and footer have read the same for this long...
const _settled = Duration(seconds: 1);

/// ...which must happen within this.
const _reloadTimeout = Duration(seconds: 15);

final _list = find.byType(OrderPage);
final _detail = find.byType(OrderDetailPage);
final _returnDialog = find.byType(ProductReturnWidget);
final _history = find.byType(ProductReturnsHistoryWidget);

/// The bill's command menu in the AppBar, an admin's.
final _billMenu = find
    .descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('คำสั่งเพิ่มเติมของบิล'))
    .hitTestable();

class OrderRobot {
  OrderRobot(this.shell) : form = FormDriver(shell);

  final ShellRobot shell;
  final FormDriver form;

  WidgetTester get tester => shell.tester;

  // --- The list -------------------------------------------------------------

  /// From anywhere in the shell: the รายการขาย tab, until today's
  /// bills have loaded without an error.
  Future<void> openList() async {
    await shell.openOrders();
    await shell.expectScreenWithoutError(find.text('ยอดรวม'));
    await pumpUntilGone(tester,
        find.descendant(of: _list, matching: find.byType(ProgressIndicator)));
  }

  Future<void> chooseFilter(String label) async {
    await tester.tap(shell.filterPill(label));
    await tester.pump();
    await _settleList();
  }

  /// The rows showing [bill]'s number and total (`฿` before it). The
  /// number is the row's title, so this is one row; the detail's header
  /// still confirms it.
  Finder _rows(Bill bill) => find.descendant(
      of: _list,
      matching: find.byWidgetPredicate((w) =>
          w is ListTile &&
          w.title is Text &&
          (w.title as Text).data == bill.code &&
          w.trailing is Text &&
          (w.trailing as Text).data == '฿${bill.totalText}'));

  /// Whether a row with [bill]'s title and total is listed, scrolling the
  /// whole list (today's bills, in the server's order).
  Future<bool> isListed(Bill bill) => scrollUntilShown(
        tester,
        find.descendant(of: _list, matching: find.byType(Scrollable)),
        _rows(bill),
        what: 'the bill row ${bill.code} ${bill.totalText}',
      );

  /// Opens the row of [bill] whose detail header shows its code; tries each
  /// row with the same title and total.
  Future<void> openBill(Bill bill) async {
    expect(await isListed(bill), isTrue,
        reason: 'bill ${bill.code} (${bill.rowTitle}) is not listed');
    if (!await _openRowOf(bill)) {
      fail('no row of the list opens bill ${bill.code}');
    }
  }

  /// Whether a row of the list, under its current filter, opens [bill]
  /// itself (its code in the detail header): exact even when another bill
  /// has the same minute and total. Leaves the list as it found it.
  Future<bool> listsBill(Bill bill) async {
    if (!await isListed(bill)) return false;
    final opened = await _openRowOf(bill);
    if (opened) await leaveBill();
    return opened;
  }

  /// [text] (exactly) on [bill]'s row, e.g. its `ยกเลิกแล้ว` mark; scroll
  /// to it first with [isListed].
  Finder rowShows(Bill bill, String text) =>
      find.descendant(of: _rows(bill), matching: find.text(text));

  /// The amount the list's foot reads next to ยอดรวม, `฿ #,##0.00`.
  String listTotal() => _totalOn(_list);

  String _totalOn(Finder screen) {
    final row = find
        .descendant(
            of: screen,
            matching: find.ancestor(
                of: find.text('ยอดรวม'), matching: find.byType(Row)))
        .first;
    return form.textsUnder(row).last;
  }

  /// Opens, one by one, each row with [bill]'s title and total until one
  /// shows its code; false (back on the list) if none does.
  Future<bool> _openRowOf(Bill bill) async {
    final count = _rows(bill).hitTestable().evaluate().length;
    for (var i = 0; i < count; i++) {
      if (i > 0) await isListed(bill);
      final rows = _rows(bill).hitTestable();
      if (i >= rows.evaluate().length) {
        fail('bill ${bill.code}: its list rows changed while they were '
            'tried (${rows.evaluate().length} left of $count)');
      }
      await tester.tap(rows.at(i));
      await tester.pump();
      await _awaitDetail();
      if (find.text(bill.header).evaluate().isNotEmpty) return true;
      await leaveBill();
    }
    return false;
  }

  Future<void> _awaitDetail() async {
    await shell.expectScreenWithoutError(
        find.descendant(of: _detail, matching: find.text('ยอดรวม')));
    // The header fills in once the bill has loaded; the admin's menu once
    // the role has been read.
    await pumpUntilFound(tester, _billMenu);
    await pumpUntilFound(
        tester, find.descendant(of: _detail, matching: find.byType(ListTile)));
    await shell.waitForSnackbarToClose();
  }

  /// The AppBar back arrow, then the list reloads.
  Future<void> leaveBill() async {
    await shell.pageBack();
    await _settleList();
  }

  /// Waits until the list's rows and footer have stopped changing for
  /// [_settled] after a reload, then watches it for errors.
  Future<void> _settleList() async {
    await pumpUntilFound(tester, find.text('ยอดรวม').hitTestable());
    var last = _listTexts();
    final quiet = Stopwatch()..start();
    final clock = Stopwatch()..start();
    while (quiet.elapsed < _settled) {
      if (clock.elapsed > _reloadTimeout) {
        fail('the bill list kept changing for $_reloadTimeout');
      }
      await tester.pump(_step);
      final now = _listTexts();
      if (!listEquals(now, last)) {
        last = now;
        quiet.reset();
      }
    }
    await shell.expectScreenWithoutError(find.text('ยอดรวม'));
  }

  /// What the list shows: every row's texts and the footer.
  List<String> _listTexts() => form.textsUnder(_list);

  // --- The detail -----------------------------------------------------------

  /// The detail row of [productName].
  Finder _line(String productName) => find
      .descendant(
          of: _detail,
          matching: find.byWidgetPredicate(
              (w) => w is OrderLineTile && w.line.product?.name == productName))
      .hitTestable();

  /// [text] (exactly) on [productName]'s row: its quantity (`2×`), paid
  /// amount or a badge such as `คืน 1`.
  Finder lineShows(String productName, String text) =>
      find.descendant(of: _line(productName), matching: find.text(text));

  /// [text] (exactly) anywhere on the detail, e.g. its Total `฿ 40.00`.
  Finder detailShows(String text) =>
      find.descendant(of: _detail, matching: find.text(text)).hitTestable();

  /// The amount the bill's foot reads next to ยอดรวม, `฿ #,##0.00`.
  String detailTotal() => _totalOn(_detail);

  /// The menu of [productName]'s row, which holds its return, history and
  /// delete; a cancelled line has none.
  Finder lineMenu(String productName) => find.descendant(
      of: _line(productName),
      matching: find.byWidgetPredicate((w) => w is PopupMenuButton));

  /// Opens [productName]'s row menu and chooses the item showing [item].
  Future<void> _chooseFromLineMenu(String productName, String item) async {
    await tester.tap(lineMenu(productName));
    await tester.pump();
    final entry = _menuItem(item);
    await pumpUntilFound(tester, entry);
    await tester.tap(entry);
    await tester.pump();
  }

  /// The open menu's item showing [item].
  Finder _menuItem(String item) => find
      .descendant(
          of: find.byWidgetPredicate((w) => w is PopupMenuItem),
          matching: find.text(item))
      .hitTestable();

  /// The row menu's คืนสินค้า opens 'รับคืนสินค้า'.
  Future<void> openReturn(String productName) async {
    await _chooseFromLineMenu(productName, 'คืนสินค้า');
    await pumpUntilFound(tester, _returnDialog.hitTestable());
  }

  Finder returnDialogShows(String text) => find
      .descendant(of: _returnDialog, matching: find.text(text))
      .hitTestable();

  /// What the return dialog's field [label] holds.
  String returnField(String label) => tester
      .widget<TextField>(form.field(label, within: _returnDialog))
      .controller!
      .text;

  /// Types [quantity] and [reason], confirms, and waits for the bill to
  /// reload with the returned badge.
  Future<void> submitReturn(
      {required int quantity, required String reason}) async {
    await form.enter('จำนวนที่คืน', '$quantity', within: _returnDialog);
    await form.enter('เหตุผลการคืน', reason, within: _returnDialog);
    await shell.tapTitleBarAction('ยืนยัน');
    await form.awaitClosed(_returnDialog);
    await shell.waitForSnackbarToClose();
    await shell.expectScreenWithoutError(_detail);
  }

  /// The bill menu's returns history opens 'ประวัติการคืนสินค้า'.
  Future<void> openReturnHistory() async {
    await _chooseFromBillMenu('ประวัติการคืนสินค้า');
    await pumpUntilFound(
        tester,
        find.descendant(
            of: find.byType(TitleBar),
            matching: find.text('ประวัติการคืนสินค้า')));
    // It is empty, then spins, then lists the returns or says there are none.
    await pumpUntil(
        tester,
        () =>
            find
                .descendant(of: _history, matching: find.byType(Card))
                .evaluate()
                .isNotEmpty ||
            find.text('ไม่มีประวัติการคืนสินค้า').evaluate().isNotEmpty,
        'the returns history to load');
  }

  Finder historyShows(String text) =>
      find.descendant(of: _history, matching: find.text(text)).hitTestable();

  /// The row menu's ลบรายการ (not the bill's ลบบิล), confirmed; the bill
  /// reloads.
  Future<void> cancelLine(String productName) async {
    await _chooseFromLineMenu(productName, 'ลบรายการ');
    await shell.confirm();
    await _awaitReload();
  }

  /// The bill menu's ลบบิล, confirmed; the detail closes and the list
  /// reloads.
  Future<void> cancelBill() async {
    await _chooseFromBillMenu('ลบบิล');
    await shell.confirm();
    await pumpUntilGone(tester, _detail, timeout: const Duration(seconds: 30));
    await _settleList();
  }

  /// Opens the bill's menu (an admin's, in the AppBar) and chooses [item].
  Future<void> _chooseFromBillMenu(String item) async {
    await tester.tap(_billMenu);
    await tester.pump();
    final entry = _menuItem(item);
    await pumpUntilFound(tester, entry);
    await tester.tap(entry);
    await tester.pump();
  }

  /// The loading snackbar shows while the bill reloads; waits it out and
  /// fails on an error.
  Future<void> _awaitReload() async {
    await shell.waitForSnackbarToClose();
    await shell.expectScreenWithoutError(_detail);
  }
}
