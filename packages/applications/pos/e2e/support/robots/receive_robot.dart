// The goods receipts under "จัดการ": the receipt list (embedded in the
// shell), the receipt page pushed over it, its add-item dialog, and the add
// supplier page pushed from it.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/presentation/receive/main/receives_widget.dart';
import '../pump.dart';
import 'form_driver.dart';
import 'product_picker.dart';
import 'shell_robot.dart';

const _manageTile = 'ใบรับสินค้า / Goods Receipt';
const _searchHint = 'ค้นหาเลขที่ใบรับสินค้า...';
const _supplierField = 'ร้านขายสินค้า';
const _itemDialogTitle = 'เพิ่มรายการรับสินค้า';

/// The add-supplier form has no validation; pos-api takes any address.
const _supplierAddress = 'E2E';

final _list = find.byType(ReceivesWidget);
final _addMenu = find.widgetWithText(ListTile, 'เพิ่มใบรับสินค้า');
final _createButton = find.byKey(const Key('add'));
final _addItemButton = find.byKey(const Key('product'));
final _importButton = find.byKey(const Key('import-receive'));
final _importedMarker = find.byKey(const Key('receive-imported'));
final _itemDialog = find.ancestor(
    of: find.text(_itemDialogTitle), matching: find.byType(AlertDialog));

/// One line of a receipt.
class ReceiptItem {
  const ReceiptItem({
    required this.productName,
    required this.quantity,
    required this.cost,
    required this.lot,
    required this.expiry,
  });

  final String productName;
  final int quantity;
  final double cost;
  final String lot;

  /// YYYY-MM-DD, as the dialog takes it.
  final String expiry;
}

class ReceiveRobot {
  ReceiveRobot(this.shell) : form = FormDriver(shell);

  final ShellRobot shell;
  final FormDriver form;

  WidgetTester get tester => shell.tester;

  // --- The list -------------------------------------------------------------

  /// From anywhere in the shell: จัดการ → the goods-receipt tile, until the
  /// list has loaded without an error.
  Future<void> openList() async {
    await shell.openManage();
    await shell.openManageTile(_manageTile);
    await _awaitListLoaded();
  }

  Future<void> _awaitListLoaded() async {
    await shell.expectScreenWithoutError(shell.searchField(_searchHint));
    await pumpUntilGone(tester,
        find.descendant(of: _list, matching: find.byType(ProgressIndicator)));
    expect(find.text('ลองอีกครั้ง'), findsNothing,
        reason: 'the receipt list failed to load');
  }

  Finder _row(String code) => find
      .descendant(
          of: _list,
          matching: find.byWidgetPredicate((w) =>
              w is ListTile &&
              w.title is Text &&
              (w.title as Text).data == code))
      .hitTestable();

  /// Whether the list shows the receipt [code] once searched for.
  Future<bool> isListed(String code) async {
    await tester.enterText(shell.searchField(_searchHint), code);
    await tester.pump();
    return _row(code).evaluate().isNotEmpty;
  }

  /// Opens the receipt [code] from the list.
  Future<void> openListed(String code) async {
    expect(await isListed(code), isTrue, reason: 'receipt $code not listed');
    await tester.tap(_row(code));
    await tester.pump();
    await form.awaitOutcome(shell.appBarTitle('รับสินค้า'));
  }

  /// The receipt page's back arrow; the list reloads behind it.
  Future<void> leave() async {
    await _back(shell.appBarTitle('รับสินค้า'));
    await _awaitListLoaded();
  }

  // --- A new receipt --------------------------------------------------------

  /// 'เพิ่มใบรับสินค้า', picks [supplierName] (adding it first through the
  /// add-supplier page if the picker lacks it), types [reference] and
  /// creates the receipt; returns once it can take items.
  Future<void> create({
    required String supplierName,
    required String reference,
  }) async {
    await tester.tap(_addMenu.hitTestable());
    await tester.pump();
    await form.awaitOutcome(_createButton);
    if (!_supplierOptions().contains(supplierName)) {
      await _addSupplier(supplierName);
    }
    await form.choose(_supplierField, supplierName);
    await form.enter('หมายเลขอางอิง', reference);
    await tester.tap(_createButton.hitTestable());
    await tester.pump();
    await form.awaitOutcome(_addItemButton);
    await shell.expectSnackbar('Add success');
  }

  /// The supplier names the picker offers.
  List<String> _supplierOptions() {
    final picker = find.byType(DropdownButton<Supplier>);
    if (picker.evaluate().isEmpty) return const [];
    final items = tester.widget<DropdownButton<Supplier>>(picker).items ?? [];
    return [
      for (final item in items)
        if (item.value case final s?) s.name
    ];
  }

  /// The picker's add button, the add-supplier form, and back; the receipt
  /// page reloads its suppliers on return.
  Future<void> _addSupplier(String name) async {
    await tester.tap(find.byKey(const Key('supplier')).hitTestable());
    await tester.pump();
    final page = shell.appBarTitle('เพิ่มร้านค้า');
    await pumpUntilFound(tester, page);
    await form.enter('Name*', name);
    await form.enter('Address*', _supplierAddress);
    await tester.tap(find.byKey(const Key('add')).hitTestable());
    await tester.pump();
    await shell.expectSnackbar('Add $name success');
    await _back(page);
    await pumpUntil(tester, () => _supplierOptions().contains(name),
        'the supplier picker to offer $name');
  }

  /// Taps the top page's back arrow and waits for [page] to leave (the page
  /// under it has a back arrow too).
  Future<void> _back(Finder page) async {
    await tester.tap(find.byType(BackButton).hitTestable().last);
    await tester.pump();
    await pumpUntilGone(tester, page);
  }

  // --- Items, import, delete ------------------------------------------------

  /// 'เพิ่มรายการสินค้า', fills the dialog and adds the line; returns once
  /// the saved line is listed.
  Future<void> addItem(ReceiptItem item) async {
    await tester.tap(_addItemButton.hitTestable());
    await tester.pump();
    await pumpUntilFound(tester, _itemDialog.hitTestable());
    // The product is chosen through the product picker and its search.
    await tester.tap(form.field('สินค้า', within: _itemDialog));
    await tester.pump();
    await pickProductByName(shell, item.productName);
    await pumpUntilGone(tester, productPicker);
    await form.enter('จำนวน (', '${item.quantity}',
        within: _itemDialog, prefix: true);
    await form.enter('ต้นทุนต่อหน่วย', _money(item.cost), within: _itemDialog);
    await form.enter('เลขล็อต', item.lot, within: _itemDialog);
    await form.enter('วันหมดอายุ (YYYY-MM-DD)', item.expiry,
        within: _itemDialog);
    await tester.tap(find
        .descendant(
            of: _itemDialog,
            matching: find.widgetWithText(FilledButton, 'เพิ่มรายการ'))
        .hitTestable());
    await tester.pump();
    // The line can show while the dialog is still fading out, and the dialog
    // is an AlertDialog, which the error watch would take for an alert.
    await form.awaitClosed(_itemDialog);
    await form.awaitOutcome(itemRow(item));
  }

  /// The receipt line for [item]: `Name: <product>` and its quantity and
  /// unit cost.
  Finder itemRow(ReceiptItem item) => find
      .byWidgetPredicate((w) =>
          w is ListTile &&
          w.title is Text &&
          (w.title as Text).data == 'Name: ${item.productName}' &&
          w.subtitle is Text &&
          (w.subtitle as Text).data ==
              'Quantity: ${item.quantity} Cost: ${_money(item.cost)}')
      .hitTestable();

  /// 'นำเข้าสต็อก' and its confirm; returns once the page says it imported.
  Future<void> import() async {
    // The 'Update success' bar from adding the line covers this button
    // until it closes by itself.
    await shell.waitForSnackbarToClose();
    await pumpUntilFound(tester, _importButton.hitTestable());
    await tester.tap(_importButton.hitTestable());
    await tester.pump();
    await shell.confirm();
    await form.awaitOutcome(_importedMarker);
  }

  /// The receipt page shows it was imported: the marker, locked lines, and
  /// no import button.
  Future<void> expectImported() async {
    await pumpUntilFound(tester, _importedMarker.hitTestable());
    await pumpUntilFound(tester, find.byIcon(Icons.lock).hitTestable());
    expect(_importButton, findsNothing);
  }

  /// The AppBar's delete (the lines have delete icons too) and its confirm;
  /// returns once the list is back.
  Future<void> deleteDraft() async {
    await tester.tap(find
        .descendant(
            of: find.byType(AppBar), matching: find.byIcon(Icons.delete))
        .hitTestable());
    await tester.pump();
    await shell.confirm();
    await pumpUntilGone(tester, shell.appBarTitle('รับสินค้า'));
    await _awaitListLoaded();
  }

  /// A cost as the dialog and the line show it: two decimals.
  static String _money(double value) => value.toStringAsFixed(2);
}
