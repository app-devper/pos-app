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
import 'support/api/product_api.dart';
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
  });

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
      // FINDING: the line is titled with the product's id, not its name.
      // Asserted as the app behaves; the skipped test below says what a
      // user expects.
      final productId = (await productsNamed(_product)).single.id;
      expect(counts.detailShows('สินค้า $productId'), findsOneWidget,
          reason: 'the detail currently names the product by its id');
      await counts.leave();
      await counts.leave();

      // Assert: the stock is 8, and the adjustment the count made shows
      await _expectStockAfterCount(shell);
    });
  });

  // FINDING (Task 7): the detail titles each line 'สินค้า <productId>'
  // (stock_count_manage_page.dart:124); pos-api's stock count lines carry
  // only productId and stockId (entities/stock_count.go), so a user cannot
  // tell which product a count line is about.
  group('FINDING', () {
    testWidgets('the stock count detail names the counted product',
        (tester) async {
      final counts = StockCountRobot(await _signedInShell(tester));
      await counts.openList();
      await counts.open(_countNo);

      expect(counts.detailShows(_product), findsOneWidget);
    });
  },
      skip: 'FINDING: the stock count detail shows the product id, not its '
          'name (stock_count_manage_page.dart:124)');

  // FINDING (Task 7): CustomSnackBar's 'Clear' calls
  // ScaffoldMessenger.of(context) with the context of the screen that showed
  // it (design_system snack_bar.dart:65). The snackbar never closes on its
  // own and outlives that screen; once the screen is gone, 'Clear' throws
  // "Looking up a deactivated widget's ancestor is unsafe" and the snackbar
  // stays. After a receipt is imported, 'นำเข้าสต็อกสำเร็จ' sits over the
  // new stock count's 'เพิ่มสินค้า' until it is swiped away.
  group('FINDING', () {
    testWidgets('a success snackbar from an earlier screen can be cleared',
        (tester) async {
      final shell = await _signedInShell(tester);
      final name = RunData.name('count snackbar product');
      Cleanup.add('product "$name"', () => deleteProductsNamed(name));
      await stockProduct(shell,
          what: 'count snackbar product', barcodeNumber: 8);
      await StockCountRobot(shell).openList();

      await tester.tap(find.text('Clear').hitTestable());
      await tester.pump();
      await shell.waitForSnackbarToClose();
    });
  },
      skip: "FINDING: a success snackbar's Clear fails once its screen has "
          'gone, and the snackbar stays (snack_bar.dart:65)');
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
