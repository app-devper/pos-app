// The customer pages under "จัดการ" on a wide screen: the list on the left,
// and on the right the menu, the add form, a customer's detail or its edit
// form.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/widgets/loading_dialog.dart';
import 'package:design_system/widgets/title_bar.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/customer/main/customers_widget.dart';
import '../pump.dart';
import 'shell_robot.dart';

const _manageTile = 'จัดการลูกค้า';
const _listTitle = 'ข้อมูลลูกค้า';
const _addMenuItem = 'เพิ่มลูกค้า';
const _nameField = 'ชื่อลูกค้า';
const _phoneField = 'โทรศัพท์';
const _deleteButton = 'ลบลูกค้า';
const _deleteQuestion = 'ต้องการลบลูกค้าใช่หรือไม่?';

/// A save's outcome (the next panel, or an error alert) arrives over HTTP.
const _saveTimeout = Duration(seconds: 30);

/// One drag of the list; about four rows.
const _scrollStep = Offset(0, -300);
const _step = Duration(milliseconds: 100);

final _list = find.byType(CustomersWidget);
final _menu = find.widgetWithText(ListTile, _addMenuItem).hitTestable();

/// The error alert. The saving spinner is an AlertDialog too, so the alert
/// is told apart by its title.
final _alert = find.ancestor(
    of: find.text('พบข้อผิดพลาด'), matching: find.byType(AlertDialog));
final _saving = find.byType(LoadingDialog);

class CustomerRobot {
  CustomerRobot(this.shell);

  final ShellRobot shell;

  WidgetTester get tester => shell.tester;

  // --- The list -------------------------------------------------------------

  /// From anywhere in the shell: จัดการ → จัดการลูกค้า, until the list has
  /// loaded without an error.
  Future<void> openList() async {
    await shell.openManage();
    await shell.openManageTile(_manageTile);
    await _awaitListLoaded();
  }

  /// Leaves the customer page for จัดการ and comes back, which is what
  /// reloads the list on a wide screen.
  Future<void> reenterList() async {
    await shell.backFromCustomers();
    await pumpUntilFound(tester, find.text(_manageTile).hitTestable());
    await shell.openManageTile(_manageTile);
    await _awaitListLoaded();
  }

  Future<void> _awaitListLoaded() async {
    await shell.expectScreenWithoutError(find.text(_listTitle));
    await pumpUntilGone(tester,
        find.descendant(of: _list, matching: find.byType(ProgressIndicator)));
    expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsNothing,
        reason: 'the customer list failed to load');
  }

  Finder _listRow(String name) =>
      find.descendant(of: _list, matching: find.widgetWithText(ListTile, name));

  /// Scrolls the list from where it is to its end looking for [name]; true
  /// once its row is on screen. The list may hold real customers, in any
  /// order, so the E2E one is found by its exact name.
  Future<bool> scrollListTo(String name) async {
    final row = _listRow(name);
    final scrollable =
        find.descendant(of: _list, matching: find.byType(Scrollable));
    while (row.hitTestable().evaluate().isEmpty) {
      final position = tester.state<ScrollableState>(scrollable).position;
      if (position.pixels >= position.maxScrollExtent) return false;
      await tester.drag(scrollable, _scrollStep);
      await tester.pump(_step);
    }
    return true;
  }

  /// Opens [name]'s detail from the list.
  Future<void> open(String name) async {
    expect(await scrollListTo(name), isTrue, reason: '$name is not listed');
    await tester.tap(_listRow(name).hitTestable());
    await tester.pump();
    await _awaitOutcome(detailRow(_nameField, name));
  }

  // --- Add ------------------------------------------------------------------

  Finder get addFormTitle => find
      .descendant(of: _topTitleBar, matching: find.text(_addMenuItem))
      .hitTestable();

  Future<void> openAddForm() async {
    await tester.tap(_menu);
    await tester.pump();
    await pumpUntilFound(tester, addFormTitle);
  }

  /// Adds a general customer; returns once the menu is back.
  Future<void> add(String name, {required String phone}) async {
    await openAddForm();
    await _enter(_nameField, name);
    await _enter(_phoneField, phone);
    await submitForm();
    await _awaitOutcome(_menu);
  }

  /// Presses 'ยืนยัน' on the add or edit form.
  Future<void> submitForm() async {
    await shell.tapTitleBarAction('ยืนยัน');
    await tester.pump();
  }

  // --- Detail, edit, delete -------------------------------------------------

  /// The detail row [label] showing [value].
  Finder detailRow(String label, String value) => find
      .descendant(
          of: find.widgetWithText(ListTile, label), matching: find.text(value))
      .hitTestable();

  /// From the detail: 'แก้ไข', change what is given, 'ยืนยัน'; returns once
  /// the detail shows the saved phone.
  Future<void> edit({String? name, String? phone}) async {
    await shell.tapTitleBarAction('แก้ไข');
    await pumpUntilFound(tester, _field(_nameField));
    if (name != null) await _enter(_nameField, name);
    if (phone != null) await _enter(_phoneField, phone);
    await submitForm();
    await _awaitOutcome(phone == null
        ? find.text('หมายเลขลูกค้า')
        : detailRow(_phoneField, phone));
  }

  /// From the detail: 'แก้ไข', 'ลบลูกค้า', confirm; returns once the menu is
  /// back.
  Future<void> delete() async {
    await shell.tapTitleBarAction('แก้ไข');
    final button = find.widgetWithText(TextButton, _deleteButton);
    await pumpUntilFound(tester, button);
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button.hitTestable());
    await tester.pump();
    await pumpUntilFound(tester, find.text(_deleteQuestion).hitTestable());
    await shell.confirm();
    await _awaitOutcome(_menu);
  }

  // --- Form fields ----------------------------------------------------------

  Finder _field(String label) => find
      .byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label)
      .hitTestable();

  /// The field [label] showing the validation message [error].
  Finder fieldError(String label, String error) => find
      .byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.labelText == label &&
          w.decoration?.errorText == error)
      .hitTestable();

  Future<void> _enter(String label, String text) async {
    await tester.enterText(_field(label), text);
    await tester.pump();
  }

  Finder get _topTitleBar => find.byType(TitleBar).hitTestable().last;

  /// Waits for [arrived] or an error alert; fails with the alert's text, or
  /// watches [arrived] for late errors.
  Future<void> _awaitOutcome(Finder arrived) async {
    await pumpUntil(
      tester,
      () => arrived.evaluate().isNotEmpty || _alert.evaluate().isNotEmpty,
      '${arrived.describeMatch(Plurality.one)} or an error alert',
      timeout: _saveTimeout,
    );
    if (_alert.evaluate().isNotEmpty) {
      fail('Alert dialog: ${_texts(_alert).join(' | ')}');
    }
    await pumpUntilGone(tester, _saving);
    await shell.expectScreenWithoutError(arrived);
  }

  List<String> _texts(Finder within) => find
      .descendant(of: within, matching: find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data ?? '')
      .toList();
}
