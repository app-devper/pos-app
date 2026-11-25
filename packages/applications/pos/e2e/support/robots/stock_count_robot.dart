// "จัดการ" → "นับสต็อก": the list of stock counts, the new-count form with
// its product and lot picker, and a count's read-only detail.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/stock_count/main/stock_counts_page.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_item_picker_widget.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_manage_page.dart';
import '../pump.dart';
import 'form_driver.dart';
import 'scroll.dart';
import 'shell_robot.dart';

const _listTitle = 'นับสต็อก';
const _newTitle = 'นับสต็อกใหม่';
const _detailTitle = 'รายละเอียดการนับสต็อก';
const _pickerSearchHint = 'ค้นหาสินค้า...';

/// pos-api answers a count within a second locally; a hosted one is slower.
const _saveTimeout = Duration(seconds: 30);

final _list = find.byType(StockCountsPage);
final _manage = find.byType(StockCountManagePage);
final _picker = find.byType(StockCountItemPickerWidget);

class StockCountRobot {
  StockCountRobot(this.shell) : form = FormDriver(shell);

  final ShellRobot shell;
  final FormDriver form;

  WidgetTester get tester => shell.tester;

  // --- The list -------------------------------------------------------------

  /// From anywhere in the shell: จัดการ → นับสต็อก, until the list has
  /// loaded without an error.
  Future<void> openList() async {
    await shell.openManage();
    await shell.openManageTile(_listTitle);
    await shell.expectScreenWithoutError(shell.appBarTitle(_listTitle));
    await pumpUntilGone(tester,
        find.descendant(of: _list, matching: find.byType(ProgressIndicator)));
  }

  /// The list row titled [countNo]; the list is long on a shared Branch,
  /// so it is scrolled to if not built yet.
  Future<Finder> row(String countNo) async {
    final tile = find.descendant(
        of: _list,
        matching: find.byWidgetPredicate((w) =>
            w is ListTile &&
            w.title is Text &&
            (w.title as Text).data == countNo));
    final shown = await scrollUntilShown(tester,
        find.descendant(of: _list, matching: find.byType(Scrollable)), tile,
        what: 'the stock count $countNo');
    if (!shown) fail('stock count $countNo is not listed');
    return tile.hitTestable();
  }

  /// The subtitle of the row titled [countNo].
  Future<String?> rowSubtitle(String countNo) async {
    final tile = await row(countNo);
    return (tester.widget<ListTile>(tile).subtitle as Text?)?.data;
  }

  /// Opens the detail of the count [countNo] from the list.
  Future<void> open(String countNo) async {
    await tester.tap(await row(countNo));
    await tester.pump();
    await shell.expectScreenWithoutError(shell.appBarTitle(_detailTitle));
    await pumpUntilGone(tester,
        find.descendant(of: _manage, matching: find.byType(ProgressIndicator)));
  }

  /// [text] (exactly) on the open count's detail.
  Finder detailShows(String text) =>
      find.descendant(of: _manage, matching: find.text(text)).hitTestable();

  /// The AppBar back arrow: the form or detail back to the list, or the
  /// list back to จัดการ.
  Future<void> leave() async {
    final back = find.byType(BackButton).hitTestable().last;
    final page = find.ancestor(of: back, matching: find.byType(Scaffold));
    final leaving = page.evaluate().first;
    await tester.tap(back);
    await tester.pump();
    await pumpUntil(tester, () => !leaving.mounted, 'the page to close');
  }

  // --- A new count ----------------------------------------------------------

  Finder get newCountTitle => shell.appBarTitle(_newTitle);

  /// The list's AppBar add. A success bar from the receipt page may still
  /// show; it closes by itself, so the form's 'เพิ่มสินค้า' is waited for,
  /// not cleared.
  Future<void> openNew() async {
    await shell.waitForSnackbarToClose();
    await tester.tap(find
        .descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.add))
        .hitTestable());
    await tester.pump();
    await shell.expectScreenWithoutError(newCountTitle);
  }

  /// The AppBar check, which submits the count.
  Future<void> submit() async {
    await tester.tap(find
        .descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.check))
        .hitTestable());
    await tester.pump();
  }

  /// From the list: a new count noted [note], of [productName]'s [lot]
  /// (checked to hold [systemQuantity]), counted as [counted]; submits it
  /// and waits for the list to come back.
  Future<void> create({
    required String note,
    required String productName,
    required String lot,
    required int systemQuantity,
    required int counted,
  }) async {
    await openNew();
    await form.enter('หมายเหตุ', note, within: _manage);
    await _pick(productName, lot: lot, systemQuantity: systemQuantity);
    expect(
        find.descendant(
            of: _manage,
            matching: find.text('ล็อต $lot, ในระบบ $systemQuantity')),
        findsOneWidget);
    await form.enter('นับได้', '$counted', within: _manage);
    await submit();
    await pumpUntil(
        tester,
        () =>
            _manage.evaluate().isEmpty ||
            find.byType(SnackBar).evaluate().isNotEmpty,
        'the count to be saved',
        timeout: _saveTimeout);
    if (_manage.evaluate().isNotEmpty) {
      // Still on the form: fail with the error snackbar it shows.
      await shell.expectScreenWithoutError(newCountTitle);
      fail('the stock count was not saved and no error was shown');
    }
    await shell.expectScreenWithoutError(shell.appBarTitle(_listTitle));
    await pumpUntil(
        tester,
        () => find
            .descendant(of: _list, matching: find.byType(ListTile))
            .evaluate()
            .isNotEmpty,
        'the list to reload');
  }

  /// 'เพิ่มสินค้า' → search [productName] → its row → the row of [lot].
  Future<void> _pick(String productName,
      {required String lot, required int systemQuantity}) async {
    await tester.tap(find
        .descendant(of: _manage, matching: find.text('เพิ่มสินค้า'))
        .hitTestable());
    await tester.pump();
    final search = shell.searchField(_pickerSearchHint);
    await pumpUntilFound(tester, search);
    // Typing before the products have loaded is lost: the load replaces
    // the list with every product (stock_count_item_picker_view_model.dart
    // getProducts). A row of any product means it has loaded.
    await pumpUntilFound(
        tester, find.descendant(of: _picker, matching: find.byType(ListTile)),
        timeout: _saveTimeout);
    await tester.enterText(search, productName);
    await tester.pump();
    await pumpUntilFound(
        tester, _inPicker(find.widgetWithText(ListTile, productName)));
    // The search field holds the name too; the row is a ListTile.
    await tester.tap(_inPicker(find.widgetWithText(ListTile, productName)));
    await tester.pump();
    final lotRow = _inPicker(find.text('ล็อต $lot'));
    await pumpUntilFound(tester, lotRow);
    expect(
        find.descendant(
            of: find.ancestor(of: lotRow, matching: find.byType(ListTile)),
            matching: find.text('คงเหลือในระบบ: $systemQuantity')),
        findsOneWidget);
    await tester.tap(lotRow);
    await tester.pump();
    await pumpUntilGone(tester, _picker);
  }

  Finder _inPicker(Finder finder) =>
      find.descendant(of: _picker, matching: finder).hitTestable();
}
