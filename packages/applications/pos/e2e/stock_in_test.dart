// A product is created, stock comes in through a Goods Receipt, and an
// adjustment moves it up and down; a draft receipt is deleted. Run with
// tools/e2e/run.sh <local|hosted> stock_in_test.dart.
//
// The four tests are one ordered chain sharing the run's product: each one
// fails at once, naming the step that broke, when an earlier one failed.
// Every step touches only the run's own product and receipts and the one
// kept supplier "E2E supplier", so the hosted target runs all of it.

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'support/api/product_api.dart';
import 'support/api/receive_api.dart';
import 'support/app.dart';
import 'support/cleanup.dart';
import 'support/env.dart';
import 'support/fixtures.dart';
import 'support/robots/product_robot.dart';
import 'support/robots/receive_robot.dart';
import 'support/robots/shell_robot.dart';
import 'support/run_data.dart';
import 'support/stock_plan.dart';

const _unit = 'ชิ้น';
const _price = 25.0;
const _cost = 10.0;
const _received = 10;
const _adjustBy = 2;
const _adjustNote = 'E2E adjustment';

final _product = RunData.name('product');
final _barcode = RunData.barcode(1);
final _lot = runLot(E2EEnv.runId);
final _expiry = expiryOneYearAfter(DateTime.now());
final _reference = E2EEnv.runId;
final _draftReference = '${E2EEnv.runId}-draft';

final _chain = StepChain();

void main() {
  initE2E();

  // Registered here, the product's removal runs after the file's last test
  // (and, being first in, after every other undo).
  setUpAll(() => deleteProductAfterFile(_product));

  testWidgets('a product can be created and appears in the list',
      (tester) async {
    await _step('create the product', () async {
      // Arrange
      final products = await _openProducts(tester);
      await products.openAddForm();

      // Act
      await products.submitAddForm();

      // Assert
      expect(products.fieldError('ชื่อสินค้า', 'โปรดระบุชื่อสินค้า'),
          findsOneWidget);
      expect(products.addFormTitle, findsOneWidget,
          reason: 'the form should stay open, nothing saved');

      // Act
      await products.fillAddForm(_newProduct);
      await products.submitAddForm();
      await products.awaitAdded();

      // Assert
      expect(await products.isListed(_product), isTrue,
          reason: 'the new product should be listed');
      expect(await productsNamed(_product), hasLength(1));
    });
  }, timeout: e2eTestTimeout);

  testWidgets('receiving 10 and importing puts 10 in stock', (tester) async {
    await _step('receive and import', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      final receives = ReceiveRobot(shell);
      await receives.openList();

      // Act
      final code = await receiveAndImport(receives, _receipt);

      // Assert: the receipt, reopened from the list, shows it was imported
      await receives.openListed(code);
      await receives.expectImported();
      await receives.leave();
      expect(await receiveStatus(code), importedReceiveStatus);

      // Assert: the product shows 10 on hand, and the lot's row
      final products = ProductRobot(shell);
      await products.openList();
      await products.expectStockOnHand(_product, _received, unit: _unit);
      await products.open(_product);
      await products.openTab('สต็อก');
      expect(products.stockTotal(_received, _unit), findsOneWidget);
      expect(products.stockRowExpiring(shortDate(_expiry)), findsOneWidget);
    });
  }, timeout: e2eTestTimeout);

  testWidgets('an adjustment up then down changes the stock by that much',
      (tester) async {
    await _step('adjust the stock', () async {
      // Arrange
      final products = await _openProducts(tester);
      await products.open(_product);
      await products.openTab('สต็อก');

      // Act / Assert: the dialog names the received lot
      await products.adjust(
        lot: _lot,
        onHand: _received,
        increase: true,
        quantity: _adjustBy,
        note: _adjustNote,
      );
      await products.expectStockOnHand(_product, 12, unit: _unit);
      expect(products.stockTotal(12, _unit), findsOneWidget);

      await products.adjust(
        lot: _lot,
        onHand: 12,
        increase: false,
        quantity: _adjustBy,
        note: _adjustNote,
      );
      await products.expectStockOnHand(_product, 10, unit: _unit);
      expect(products.stockTotal(10, _unit), findsOneWidget);

      // Assert: the history lists the receipt and both adjustments
      await products.openTab('ประวัติ');
      expect(products.historyRow('เพิ่มสต็อกสินค้า $_lot จำนวน 10'),
          findsOneWidget);
      expect(products.historyRow('ปรับสต็อกสินค้า (อื่นๆ) จำนวน 2'),
          findsOneWidget);
      expect(products.historyRow('ปรับสต็อกสินค้า (อื่นๆ) จำนวน -2'),
          findsOneWidget);

      // Assert: the note typed with each adjustment shows on the
      // adjustments tab (the history description carries only the reason)
      await products.openTab('ปรับสต็อก');
      expect(products.adjustmentNote(_adjustNote), findsNWidgets(2));
      expect(products.adjustmentDelta('+2'), findsOneWidget);
      expect(products.adjustmentDelta('-2'), findsOneWidget);
    });
  }, timeout: e2eTestTimeout);

  testWidgets('a draft receive can be deleted', (tester) async {
    await _step('delete a draft receive', () async {
      // Arrange
      final receives = ReceiveRobot(await _signedInShell(tester));
      await receives.openList();
      Cleanup.add('draft receive $_draftReference',
          () => cancelDraftReceivesWithReference(_draftReference));
      await receives.create(
          supplierName: keptSupplierName, reference: _draftReference);
      await receives.leave();
      final code = await receiveCodeFor(_draftReference);
      expect(await receives.isListed(code), isTrue);

      // Act
      await receives.openListed(code);
      await receives.deleteDraft();

      // Assert: pos-api only cancels a deleted receipt and still returns
      // it; the app leaves cancelled receipts out of the list. The server
      // shows the deletion was recorded.
      expect(await receives.isListed(code), isFalse,
          reason: 'a deleted draft receipt leaves the list');
      expect(await receiveStatus(code), cancelledReceiveStatus);
    });
  }, timeout: e2eTestTimeout);

  // Was a finding (#8): pos-api cancels a deleted draft and returns it
  // from GET /receives; ReceivesViewModel now leaves cancelled ones out.
  group('receive removal', () {
    testWidgets('a deleted draft receive is no longer listed', (tester) async {
      // Arrange
      final receives = ReceiveRobot(await _signedInShell(tester));
      await receives.openList();
      final reference = '${E2EEnv.runId}-removed';
      Cleanup.add('draft receive $reference',
          () => cancelDraftReceivesWithReference(reference));

      // Act
      await receives.create(
          supplierName: keptSupplierName, reference: reference);
      await receives.deleteDraft();
      final code = await receiveCodeFor(reference);

      // Assert
      expect(await receives.isListed(code), isFalse);
    }, timeout: e2eTestTimeout);
  });

  // Was finding #17: the receipt page's picker overflowed its 50 px box
  // once a supplier existed. flutter_test fails this on any overflow.
  group('supplier picker layout', () {
    testWidgets('the receipt page shows the chosen supplier without overflow',
        (tester) async {
      // Arrange
      final receives = ReceiveRobot(await _signedInShell(tester));
      await receives.openList();
      final reference = '${E2EEnv.runId}-picker';
      Cleanup.add('draft receive $reference',
          () => cancelDraftReceivesWithReference(reference));

      // Act
      await receives.create(
          supplierName: keptSupplierName, reference: reference);

      // Assert: flutter_test fails the test on the overflow it reports
      expect(receives.form.dropdown('ร้านขายสินค้า'), findsOneWidget);
    }, timeout: e2eTestTimeout);
  });

  // Was a finding (#11): the green success bars never closed on their own,
  // and on the receipt page one covered 'นำเข้าสต็อก' until it was cleared.
  group('success snackbar', () {
    testWidgets('the receipt page success snackbar closes on its own',
        (tester) async {
      // Arrange
      final receives = ReceiveRobot(await _signedInShell(tester));
      await receives.openList();
      final reference = '${E2EEnv.runId}-snackbar';
      Cleanup.add('draft receive $reference',
          () => cancelDraftReceivesWithReference(reference));

      // Act: create shows 'เพิ่มสำเร็จ'
      await receives.create(
          supplierName: keptSupplierName, reference: reference);

      // Assert: its timer is 4 s; the wait's bound is ample
      await receives.shell.waitForSnackbarToClose();
    }, timeout: e2eTestTimeout);
  });

  // Was a finding (#15): the stock tab showed a lot's dates, cost, price and
  // quantities but never its number; it now has a ล็อต column.
  group('lot number on the stock tab', () {
    testWidgets('the stock tab shows the received lot number', (tester) async {
      // Arrange
      final products = await _openProducts(tester);
      await products.open(_product);

      // Act
      await products.openTab('สต็อก');

      // Assert
      expect(products.textOnScreen(_lot), findsOneWidget);
    }, timeout: e2eTestTimeout);
  });
}

final _newProduct = NewProduct(
  name: _product,
  barcode: _barcode,
  unit: _unit,
  price: _price,
  cost: _cost,
);

final _receipt = Receipt(
  supplierName: keptSupplierName,
  reference: _reference,
  item: ReceiptItem(
    productName: _product,
    quantity: _received,
    cost: _cost,
    lot: _lot,
    expiry: _expiry,
  ),
);

/// One step of the chain.
Future<void> _step(String name, Future<void> Function() body) =>
    _chain.run(name, body);

/// Launches the app signed in as admin (once per file).
Future<ShellRobot> _signedInShell(WidgetTester tester) async {
  await launchApp(tester, keepSession: true);
  await continueSignedIn(tester);
  return ShellRobot(tester);
}

Future<ProductRobot> _openProducts(WidgetTester tester) async {
  final products = ProductRobot(await _signedInShell(tester));
  await products.openList();
  return products;
}
