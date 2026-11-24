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
import 'support/known_faults.dart';
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
  });

  testWidgets('receiving 10 and importing puts 10 in stock', (tester) async {
    await _step('receive and import', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      final receives = ReceiveRobot(shell);
      await receives.openList();

      // Act
      final code = await receiveAndImport(receives, _receipt);

      // Assert: the receipt, reopened from the list, shows it was imported
      await onReceiptPage(() async {
        await receives.openListed(code);
        await receives.expectImported();
        await receives.leave();
      });
      expect(await receiveStatus(code), importedReceiveStatus);
      expect(supplierPickerOverflowsSwallowed, greaterThanOrEqualTo(1),
          reason: 'The supplier picker no longer overflows: delete '
              'onReceiptPage from known_faults.dart and its callers, and '
              'unskip the "supplier picker layout" FINDING test.');

      // Assert: the product shows 10 on hand, and the lot's row
      final products = ProductRobot(shell);
      await products.openList();
      await products.expectStockOnHand(_product, _received, unit: _unit);
      await products.open(_product);
      await products.openTab('สต็อก');
      expect(products.stockTotal(_received, _unit), findsOneWidget);
      expect(products.stockRowExpiring(shortDate(_expiry)), findsOneWidget);
    });
  });

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
    });
  });

  testWidgets('a draft receive can be deleted', (tester) async {
    await _step('delete a draft receive', () async {
      // Arrange
      final receives = ReceiveRobot(await _signedInShell(tester));
      await receives.openList();
      Cleanup.add('draft receive $_draftReference',
          () => cancelDraftReceivesWithReference(_draftReference));
      final code = await onReceiptPage(() async {
        await receives.create(
            supplierName: keptSupplierName, reference: _draftReference);
        await receives.leave();
        return receiveCodeFor(_draftReference);
      });
      expect(await receives.isListed(code), isTrue);

      // Act
      await onReceiptPage(() async {
        await receives.openListed(code);
        await receives.deleteDraft();
      });

      // Assert
      // FINDING: pos-api only cancels a deleted receipt and lists cancelled
      // ones too, and the app does not filter them, so it stays listed.
      // Asserted as the app behaves; the skipped test below says what a
      // user expects. The server shows the deletion was recorded.
      expect(await receives.isListed(code), isTrue,
          reason: 'the app currently keeps listing a deleted receipt');
      expect(await receiveStatus(code), cancelledReceiveStatus);
    });
  });

  // FINDING (Task 7): DELETE /receives/:id sets status CANCELLED
  // (pos-api app/data/repositories/receive.go:522-535) and GET /receives
  // returns every status (receive.go:117-142); ReceivesViewModel shows them
  // all (receives_view_model.dart:48-50), so a deleted draft never leaves the
  // list. Skipped tests do not sign in or write anything.
  group('receive removal', () {
    testWidgets('a deleted draft receive is no longer listed', (tester) async {
      // Arrange
      final receives = ReceiveRobot(await _signedInShell(tester));
      await receives.openList();
      final reference = '${E2EEnv.runId}-removed';
      Cleanup.add('draft receive $reference',
          () => cancelDraftReceivesWithReference(reference));

      // Act
      final code = await onReceiptPage(() async {
        await receives.create(
            supplierName: keptSupplierName, reference: reference);
        await receives.deleteDraft();
        return receiveCodeFor(reference);
      });

      // Assert
      expect(await receives.isListed(code), isFalse);
    });
  },
      skip: 'FINDING: a deleted draft receipt stays in the list (pos-api '
          'cancels it and lists cancelled receipts; receives_view_model.dart:48-50 '
          'does not filter them)');

  // FINDING (Task 7): see known_faults.dart. Once a supplier exists, the
  // receipt page's picker overflows its 50 px box; the running tests let
  // exactly that error through, this one does not.
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
    });
  },
      skip: 'FINDING: the receipt page squeezes the supplier picker into '
          '50 px and it overflows (receive_manage_page.dart:225)');

  // FINDING (Task 7): see ReceiveRobot.dismissSuccessSnackbar. The green
  // success snackbars carry a 'Clear' action and so never close on their
  // own; on the receipt page one covers 'นำเข้าสต็อก' until it is cleared.
  group('success snackbar', () {
    testWidgets('the receipt page success snackbar closes on its own',
        (tester) async {
      // Arrange
      final receives = ReceiveRobot(await _signedInShell(tester));
      await receives.openList();
      final reference = '${E2EEnv.runId}-snackbar';
      Cleanup.add('draft receive $reference',
          () => cancelDraftReceivesWithReference(reference));

      await onReceiptPage(() async {
        // Act: create shows 'Add success'
        await receives.create(
            supplierName: keptSupplierName, reference: reference);

        // Assert: its timer is 3 s; 20 s is ample
        await receives.shell.waitForSnackbarToClose();
      });
    });
  },
      skip: 'FINDING: success snackbars never close on their own and cover '
          'the import button (design_system snack_bar.dart:44)');

  // FINDING (Task 7): the stock tab shows a lot's import date, expiry, cost,
  // price and quantities but never its lot number
  // (product_detail_widget.dart:593-870); a user who received lot L… can
  // only find it by opening the adjustment dialog on each row.
  group('lot number on the stock tab', () {
    testWidgets('the stock tab shows the received lot number', (tester) async {
      // Arrange
      final products = await _openProducts(tester);
      await products.open(_product);

      // Act
      await products.openTab('สต็อก');

      // Assert
      expect(products.textOnScreen(_lot), findsOneWidget);
    });
  },
      skip: 'FINDING: the product stock tab never shows the lot number '
          '(product_detail_widget.dart:593)');
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

/// One step of the chain. Receipt-page steps inside it go through
/// onReceiptPage; nothing else is tolerated.
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
