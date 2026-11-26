// A stock count: an empty one is refused, and counting 8 of the run's lot of
// 10 sets its stock to 8 and records the difference. Run with
// tools/e2e/run.sh <local|hosted> stock_count_test.dart.
//
// The two tests are one ordered chain. A stock count cannot be deleted or
// undone (pos-api has no route for it), so the count this file records is
// reported as kept; every admin of the Branch sees it in the นับสต็อก list.
// Everything else it touches is the run's own product, its receipt and the
// kept "E2E supplier", so the hosted target runs all of it.
//
// Stock on hand, read on the product list: 10 → count of 8 → 8.

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'support/api/stock_count_api.dart';
import 'support/app.dart';
import 'support/cleanup.dart';
import 'support/fixtures.dart';
import 'support/robots/product_robot.dart';
import 'support/robots/shell_robot.dart';
import 'support/robots/stock_count_robot.dart';
import 'support/run_data.dart';
import 'support/stock_plan.dart';

const _counted = 8;

final _product = RunData.name('count product');
final _note = RunData.name('stock count');
final _chain = StepChain();

late StockedProduct _stocked;
late String _countNo;

void main() {
  initE2E();

  setUpAll(() => deleteProductAfterFile(_product));

  testWidgets('a stock count with no product is refused', (tester) async {
    await _step('refuse an empty count', () async {
      // Arrange
      final counts = StockCountRobot(await _signedInShell(tester));
      await counts.openList();
      await counts.openNew();

      // Act
      await counts.submit();

      // Assert
      await counts.shell
          .expectSnackbar('Error: โปรดเพิ่มสินค้าอย่างน้อย 1 รายการ');
      expect(counts.newCountTitle, findsOneWidget,
          reason: 'the form should stay open, nothing saved');
      await counts.shell.waitForSnackbarToClose();
      await counts.leave();
    });
  }, timeout: e2eTestTimeout);

  testWidgets(
      'counting 8 where the system has 10 sets the stock to 8 and records '
      'the difference', (tester) async {
    await _step('count 8 of 10', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      _stocked =
          await stockProduct(shell, what: 'count product', barcodeNumber: 6);
      final counts = StockCountRobot(shell);
      await counts.openList();

      // Declared first: once saved, a count can never be deleted.
      Cleanup.keep('stock count with note "$_note" (cannot be deleted)');

      // Act
      await counts.create(
        note: _note,
        productName: _product,
        lot: _stocked.lot,
        systemQuantity: _stocked.quantity,
        counted: _counted,
      );
      _countNo = await stockCountNoWithNote(_note);
      debugPrint('E2E: the stock count noted "$_note" is $_countNo');

      // Assert: the list holds the count, of one line. Found by its number,
      // not by position: another admin may count in the same seconds.
      expect(await counts.rowSubtitle(_countNo),
          startsWith('รายการ: 1, วันที่: '));

      // Assert: its detail shows the line's figures and the difference
      await counts.open(_countNo);
      expect(counts.detailShows(_countNo), findsOneWidget);
      expect(counts.detailShows(_note), findsOneWidget);
      expect(counts.detailShows('ในระบบ 10 / นับได้ 8'), findsOneWidget);
      expect(counts.detailShows('-2'), findsOneWidget);
      // The line is titled with the product's name (was finding #9).
      expect(counts.detailShows(_product), findsOneWidget,
          reason: 'the detail names the counted product');
      await counts.leave();
      await counts.leave();

      // Assert: the stock is 8, and the adjustment the count made shows
      await _expectStockAfterCount(shell);
    });
  }, timeout: e2eTestTimeout);

  // Was a finding (#9): pos-api's count lines carry only ids, and the detail
  // titled each 'สินค้า <productId>'; it now looks the names up.
  group('count line names', () {
    testWidgets('the stock count detail names the counted product',
        (tester) async {
      final counts = StockCountRobot(await _signedInShell(tester));
      await counts.openList();
      await counts.open(_countNo);

      expect(counts.detailShows(_product), findsOneWidget);
    }, timeout: e2eTestTimeout);
  });

  // Was a finding (#12): a success bar outlived the screen that showed it,
  // and its 'Clear' then threw "Looking up a deactivated widget's ancestor
  // is unsafe" and left it over the stock count's 'เพิ่มสินค้า'. It now
  // closes by itself, and its 'Clear' uses the messenger, not the screen.
  // What this checks: the bar is gone within the wait and nothing threw.
  // 'Clear' is pressed only if the bar still shows when the stock count
  // opens; it has usually closed by then, so the press is not guaranteed
  // (the messenger's Clear has its own widget test).
  group('success bar from an earlier screen', () {
    testWidgets(
        'an earlier screen\'s success bar closes by itself on the stock '
        'count, with no error', (tester) async {
      // Arrange: importing a receipt shows 'นำเข้าสต็อกสำเร็จ'
      final shell = await _signedInShell(tester);
      final name = RunData.name('count snackbar product');
      deleteProductAfterFile(name);
      await stockProduct(shell,
          what: 'count snackbar product', barcodeNumber: 8);

      // Act: the receipt page is gone once the stock count is open
      await StockCountRobot(shell).openList();
      final clear = find.text('Clear').hitTestable();
      if (clear.evaluate().isNotEmpty) {
        await tester.tap(clear.first);
        await tester.pump();
      }
      await shell.waitForSnackbarToClose();

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('snackbar')), findsNothing);
    }, timeout: e2eTestTimeout);
  });
}

/// The list, the stock tab and the adjustments tab after the count.
Future<void> _expectStockAfterCount(ShellRobot shell) async {
  final products = ProductRobot(shell);
  await products.openList();
  await products.expectStockOnHand(_product, _counted, unit: _stocked.unit);
  await products.open(_product);
  await products.openTab('สต็อก');
  expect(products.stockTotal(_counted, _stocked.unit), findsOneWidget);
  await products.openTab('ประวัติ');
  expect(products.historyRow('ปรับสต็อกสินค้า (นับสต็อก) จำนวน -2'),
      findsOneWidget);
  await products.openTab('ปรับสต็อก');
  // pos-api notes the adjustment as '<count no> <note>' (ledger/adjust.go:82).
  expect(products.adjustmentNote('$_countNo $_note'), findsOneWidget);
  expect(products.adjustmentDelta('-2'), findsOneWidget);
}

/// One step of the chain.
Future<void> _step(String name, Future<void> Function() body) =>
    _chain.run(name, body);

/// Launches the app signed in as admin (once per file).
Future<ShellRobot> _signedInShell(WidgetTester tester) async {
  await launchApp(tester, keepSession: true);
  await continueSignedIn(tester);
  return ShellRobot(tester);
}
