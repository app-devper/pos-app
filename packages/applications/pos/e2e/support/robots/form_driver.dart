// Fields, dropdowns and save outcomes the way the product and receipt
// screens build them. (The customer robot keeps private copies of a few of
// these; it is left as it is.)

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/widgets/loading_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../pump.dart';
import 'scroll.dart';
import 'shell_robot.dart';

/// A save's outcome (the next screen, or an error alert) arrives over HTTP.
const _saveTimeout = Duration(seconds: 30);

/// The error alert. The saving spinner is an AlertDialog too, so the alert
/// is told apart by its title.
final _alert = find.ancestor(
    of: find.text('พบข้อผิดพลาด'), matching: find.byType(AlertDialog));
final _saving = find.byType(LoadingDialog);

class FormDriver {
  FormDriver(this.shell);

  final ShellRobot shell;

  WidgetTester get tester => shell.tester;

  /// The text field labelled [label] (exactly, or starting with it when
  /// [prefix]), under [within] if given.
  Finder field(String label, {Finder? within, bool prefix = false}) {
    final match = find.byWidgetPredicate((w) {
      final text = w is TextField ? w.decoration?.labelText : null;
      if (text == null) return false;
      return prefix ? text.startsWith(label) : text == label;
    });
    final scoped =
        within == null ? match : find.descendant(of: within, matching: match);
    return scoped.hitTestable();
  }

  /// The field [label] showing the validation message [error].
  Finder fieldError(String label, String error) => find
      .byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.labelText == label &&
          w.decoration?.errorText == error)
      .hitTestable();

  Future<void> enter(String label, String text,
      {Finder? within, bool prefix = false}) async {
    final target = field(label, within: within, prefix: prefix);
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.enterText(target, text);
    await tester.pump();
  }

  /// The dropdown labelled [label] (its InputDecorator), under [within].
  Finder dropdown(String label, {Finder? within}) {
    final match = find.byWidgetPredicate(
        (w) => w is InputDecorator && w.decoration.labelText == label);
    final scoped =
        within == null ? match : find.descendant(of: within, matching: match);
    return scoped.hitTestable();
  }

  /// Opens the dropdown labelled [label] and picks [option], scrolling the
  /// menu to it if it is long.
  Future<void> choose(String label, String option, {Finder? within}) async {
    final target = dropdown(label, within: within);
    await pumpUntilFound(tester, target);
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
    final menu = find.byType(Scrollable).last;
    await pumpUntilFound(tester, menu);
    final menuElement = menu.evaluate().last;
    final item = find.text(option);
    // A real catalogue's menu is long and unsorted: scroll it from the top
    // until the option shows or the menu ends.
    final shown = await scrollUntilShown(
        tester, find.byElementPredicate((e) => e == menuElement), item,
        what: '"$option" in the $label menu');
    if (!shown) fail('"$option" is not in the $label menu');
    await tester.tap(item.hitTestable().last);
    await tester.pump();
    await pumpUntil(tester, () => !menuElement.mounted,
        'the $label menu to close on $option');
    // The field may clip what it shows (see known_faults.dart), so its
    // choice is read from the tree, not from what takes taps.
    expect(
        find.descendant(
            of: dropdown(label, within: within), matching: find.text(option)),
        findsWidgets,
        reason: '$label should show $option');
  }

  /// Waits for [arrived] or an error alert; fails with the alert's text, or
  /// waits out the saving spinner and watches [arrived] for late errors.
  Future<void> awaitOutcome(Finder arrived) async {
    await pumpUntil(
      tester,
      () =>
          arrived.hitTestable().evaluate().isNotEmpty ||
          _alert.evaluate().isNotEmpty,
      '${arrived.describeMatch(Plurality.one)} or an error alert',
      timeout: _saveTimeout,
    );
    if (_alert.evaluate().isNotEmpty) {
      fail('Alert dialog: ${textsUnder(_alert).join(' | ')}');
    }
    await pumpUntilGone(tester, _saving, timeout: _saveTimeout);
    await shell.expectScreenWithoutError(arrived);
  }

  /// Waits for [dialog] to close or an error alert; fails with the alert's
  /// text, else waits out the saving spinner.
  Future<void> awaitClosed(Finder dialog) async {
    await pumpUntil(
      tester,
      () => dialog.evaluate().isEmpty || _alert.evaluate().isNotEmpty,
      'no ${dialog.describeMatch(Plurality.many)}, or an error alert',
      timeout: _saveTimeout,
    );
    if (_alert.evaluate().isNotEmpty) {
      fail('Alert dialog: ${textsUnder(_alert).join(' | ')}');
    }
    await pumpUntilGone(tester, _saving, timeout: _saveTimeout);
  }

  List<String> textsUnder(Finder within) => find
      .descendant(of: within, matching: find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data ?? '')
      .toList();
}
