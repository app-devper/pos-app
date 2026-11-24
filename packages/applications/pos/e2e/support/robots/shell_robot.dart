// The parts of the app every screen shares: the sidebar, the "จัดการ" tiles,
// snackbars, the confirm and error dialogs, and TitleBar dialogs.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/app_shell.dart';
import 'package:design_system/widgets/title_bar.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../error_check.dart';
import '../pump.dart';

/// Long enough for a screen's first load to answer and, if it fails, for the
/// error snackbar or alert to show; the local server answers in well under it.
const _errorWatch = Duration(seconds: 2);

/// The role is read from the stored session after the shell first draws.
const _roleWatch = Duration(seconds: 1);
const _step = Duration(milliseconds: 100);

final _snackbar = find.byKey(const Key('snackbar'));

/// CustomSnackBar.showErrorSnackBar: red, text "Error: …".
final _errorRed = Colors.red[400];
final _errorAlertTitle = find.text('พบข้อผิดพลาด').hitTestable();
final _confirmTitle = find.text('แจ้งเตือน').hitTestable();

class ShellRobot {
  ShellRobot(this.tester);

  final WidgetTester tester;

  // --- Sidebar --------------------------------------------------------------

  /// The sidebar entry [label], found by the widget that draws it (the label
  /// text itself is hidden when the rail is collapsed).
  Finder sidebarItem(String label) => find
      .byWidgetPredicate((w) => w is AppSidebarAction && w.label == label)
      .hitTestable();

  Future<void> openSelling() =>
      _openFromSidebar('ขายสินค้า', find.text('ตะกร้าสินค้า #1'));

  Future<void> openOrders() =>
      _openFromSidebar('รายการขาย', find.text('สรุปรายการ'));

  Future<void> openProducts() =>
      _openFromSidebar('สินค้า', searchField('ค้นหาสิ่งที่คุณต้องการ...'));

  Future<void> openManage() =>
      _openFromSidebar('จัดการ', find.text('ร้านค้าของฉัน'));

  Future<void> openUserInfo() =>
      _openFromSidebar('ข้อมูลผู้ใช้งาน', find.text('ข้อมูลของฉัน'));

  Future<void> _openFromSidebar(String label, Finder arrived) async {
    await tester.tap(sidebarItem(label));
    await tester.pump();
    await pumpUntilFound(tester, arrived.hitTestable());
  }

  /// Taps a "จัดการ" tile; the caller waits for the screen it opens.
  Future<void> openManageTile(String label) async {
    await tester.tap(find.widgetWithText(ListTile, label).hitTestable());
    await tester.pump();
  }

  // --- Leaving a screen -----------------------------------------------------

  /// The AppBar back arrow of a pushed page; returns once the page has
  /// finished animating out (the shell itself has no back arrow).
  Future<void> pageBack() async {
    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pump();
    await pumpUntilGone(tester, find.byType(BackButton));
  }

  /// The customer list is embedded in the shell; its arrow returns to จัดการ.
  Future<void> backFromCustomers() async {
    await tester.tap(find.byIcon(Icons.arrow_back_ios).hitTestable());
    await tester.pump();
  }

  // --- Screen content -------------------------------------------------------

  Finder appBarTitle(String title) => find
      .descendant(of: find.byType(AppBar), matching: find.text(title))
      .hitTestable();

  /// A search box by its hint. The hint text itself is never hit-testable
  /// (the decorator hit-tests only the input), so match the field.
  Finder searchField(String hint) => find
      .byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == hint)
      .hitTestable();

  Finder choiceChip(String label) =>
      find.widgetWithText(ChoiceChip, label).hitTestable();

  Finder get rangeDropdown =>
      find.byWidgetPredicate((w) => w is DropdownButton).hitTestable();

  /// Waits for [screen], then watches it for [_errorWatch] and fails on the
  /// first error snackbar or alert dialog.
  ///
  /// [tolerated] is an exact error code, e.g. `[SY-404-002]`, for an app
  /// fault already reported: a snackbar carrying it is logged, not failed,
  /// and once it has closed the screen is watched again, so an error queued
  /// behind it is still caught.
  Future<void> expectScreenWithoutError(
    Finder screen, {
    String? tolerated,
  }) async {
    await pumpUntilFound(tester, screen.hitTestable());
    final sawTolerated = await _watchForErrors(tolerated);
    if (!sawTolerated) return;
    await waitForSnackbarToClose();
    await _watchForErrors(null);
  }

  /// Gives the signed-in role time to reach the shell, so that an absence
  /// asserted next is not merely "not drawn yet".
  Future<void> waitForRoleToApply() async {
    final clock = Stopwatch()..start();
    while (clock.elapsed < _roleWatch) {
      await tester.pump(_step);
    }
  }

  /// Returns whether the tolerated error was shown.
  Future<bool> _watchForErrors(String? tolerated) async {
    String? seen;
    final clock = Stopwatch()..start();
    while (true) {
      final shown = _checkErrors(tolerated);
      if (shown != null && seen == null) {
        debugPrint('E2E known finding shown: $shown');
      }
      seen ??= shown;
      if (clock.elapsed >= _errorWatch) return seen != null;
      await tester.pump(_step);
    }
  }

  /// Fails on any alert dialog, or any error snackbar but a [tolerated] one;
  /// returns the tolerated one if it is showing.
  String? _checkErrors(String? tolerated) {
    final alerts = find.byType(AlertDialog);
    if (alerts.evaluate().isNotEmpty) {
      fail('Alert dialog: ${_texts(alerts).join(' | ')}');
    }
    final errors = [
      for (final element in find.byType(SnackBar).evaluate())
        if (_errorText(element) case final text?) text,
    ];
    final unexpected = unexpectedErrors(errors, tolerated: tolerated);
    if (unexpected.isNotEmpty) fail('Error snackbar: ${unexpected.first}');
    return errors.firstOrNull;
  }

  /// The text of an error snackbar (red, or saying "Error:"), else null.
  String? _errorText(Element element) {
    final snackbar = element.widget as SnackBar;
    final text = _texts(find.byElementPredicate((e) => e == element)).join(' ');
    final isError =
        snackbar.backgroundColor == _errorRed || text.contains('Error:');
    return isError ? text : null;
  }

  // --- Snackbars and dialogs ------------------------------------------------

  Future<void> expectSnackbar(String text) => pumpUntilFound(tester,
      find.descendant(of: _snackbar, matching: find.text(text)).hitTestable());

  /// Snackbars outlive the screen that showed them; wait them out before
  /// judging the next screen.
  Future<void> waitForSnackbarToClose() => pumpUntilGone(tester, _snackbar);

  /// Presses 'ยืนยัน' in the 'แจ้งเตือน' confirm dialog.
  Future<void> confirm() => _pressInDialog(_confirmTitle, 'ยืนยัน');

  /// Presses 'ตกลง' in the 'พบข้อผิดพลาด' alert.
  Future<void> dismissAlert() => _pressInDialog(_errorAlertTitle, 'ตกลง');

  Future<void> _pressInDialog(Finder title, String button) async {
    await pumpUntilFound(tester, title);
    final dialog = find.ancestor(of: title, matching: find.byType(AlertDialog));
    await tester.tap(find
        .descendant(
            of: dialog, matching: find.widgetWithText(TextButton, button))
        .hitTestable());
    await tester.pump();
    await pumpUntilGone(tester, title);
  }

  /// Presses the right-hand action [label] of the TitleBar on top.
  Future<void> tapTitleBarAction(String label) => _tapInTopTitleBar(label);

  /// Presses 'ปิด' on the TitleBar on top.
  Future<void> closeDialog() => _tapInTopTitleBar('ปิด');

  Future<void> _tapInTopTitleBar(String label) async {
    final top = find.byType(TitleBar).hitTestable().last;
    await tester.tap(find.descendant(
        of: top, matching: find.widgetWithText(TextButton, label)));
    await tester.pump();
  }

  /// Every text under [within], plain or rich.
  List<String> _texts(Finder within) => find
      .descendant(of: within, matching: find.byType(RichText))
      .evaluate()
      .map((e) => (e.widget as RichText).text.toPlainText())
      .toList();
}
