// A product of the run's own is sold through the selling screen (cash and
// PromptPay, with a customer and a line discount), a short payment is
// refused, and the bills are found under รายการขาย, returned from and
// cancelled. Run with tools/e2e/run.sh <local|hosted> selling_test.dart.
//
// The six tests are one ordered chain sharing the run's product and bills:
// each one fails at once, naming the step that broke, when an earlier one
// failed. Bills cannot be deleted, only cancelled: every bill this file
// records is cancelled before it ends (on screen, or by the clean-up), so
// the stock is whole again before the product is deleted.
//
// Stock on hand, read on the product list after each step:
//   10 → sale of 3 → 7 → refused payment → 7 → sale of 2 → 5
//      → return 1 → 6 → cancel bill 2's line (2 sold − 1 returned) → 7
//      → cancel bill 1 → 10

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'support/api/order_api.dart';
import 'support/app.dart';
import 'support/cleanup.dart';
import 'support/fixtures.dart';
import 'support/robots/cart_robot.dart';
import 'support/robots/order_robot.dart';
import 'support/robots/product_robot.dart';
import 'support/robots/shell_robot.dart';
import 'support/run_data.dart';
import 'support/sale_customer.dart';
import 'support/selling_faults.dart';
import 'support/stock_plan.dart';

const _unknownBarcode = '0000000000000';
const _billsRecorded = 2;

final _product = RunData.name('sale product');
final _returnReason = RunData.name('return');
final _chain = StepChain();
final _bills = BillLedger(_product);

late StockedProduct _stocked;
late Bill _cashBill;
late Bill _promptPayBill;

void main() {
  initE2E();

  setUpAll(() {
    debugPrint('E2E: this file records $_billsRecorded bills and cancels '
        'both, and records 1 return that cannot be undone; the cancelled '
        'bills stay listed in รายการขาย today and its Total keeps 75.00 of '
        'them (server reports exclude them)');
    // Queued first, so it runs last: after every bill is cancelled.
    deleteProductAfterFile(_product);
    Cleanup.add('bills of "$_product"', _bills.cancelAll);
  });

  testWidgets(
      'typing a barcode and Enter adds the product; an unknown barcode '
      'says so', (tester) async {
    await _step('add by barcode', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      _stocked =
          await stockProduct(shell, what: 'sale product', barcodeNumber: 5);
      final cart = CartRobot(shell);
      await cart.open();

      // Act
      await cart.addByBarcode(_stocked.barcode);

      // Assert
      expect(cart.line(_product), findsOneWidget);
      expect(cart.lineShows(_product, '1x'), findsOneWidget);
      expect(cart.lineShows(_product, '฿25.00'), findsOneWidget);

      // Act
      await cart.addByBarcode(_unknownBarcode, found: false);

      // Assert
      await shell.expectSnackbar('Error: ไม่พบสินค้า');
      await shell.waitForSnackbarToClose();
      expect(cart.line(_product), findsOneWidget,
          reason: 'the unknown barcode leaves the sale as it was');

      // Act: take the line off again, the way a cashier would
      await cart.removeLine(_product);

      // Assert
      expect(cart.isEmpty, isTrue);
    });
  });

  testWidgets(
      'a cash sale of 3 with exact payment succeeds and takes 3 from '
      'stock', (tester) async {
    await _step('cash sale of 3', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      final cart = CartRobot(shell);
      await cart.open();
      await cart.addByBarcode(_stocked.barcode);
      await cart.setQuantity(_product, 3);
      final before = await _bills.beforeSale();

      // Assert: the cart's own figures
      expect(cart.lineShows(_product, '3x'), findsOneWidget);
      expect(cart.lineShows(_product, '฿75.00'), findsOneWidget);
      expect(cart.total(), '฿75.00');

      // Act
      await cart.openPayment();

      // Assert
      expect(cart.paymentDue('฿75.00'), findsOneWidget);
      expect(cart.payButton('รับชำระพอดี ไม่มีเงินทอน'), findsOneWidget);

      // Act
      await cart.submitPayment();

      // Assert: the cart is empty, the bill is recorded
      await cart.expectSold();
      // FINDING: the grid loads once, when the screen opens, and a sale does
      // not reload it, so it still shows 10 (skipped test below).
      expect(cart.tileShows(_product, 'คงเหลือ 10 ชิ้น'), findsOneWidget,
          reason: 'the grid currently keeps the stock it opened with');
      _cashBill = await _bills.recordNew(before);
      expect(_cashBill.totalText, '75.00');

      // Assert: stock and the bill where a user sees them
      await _expectOnHand(shell, 7);
      final orders = OrderRobot(shell);
      await orders.openList();
      await orders.openBill(_cashBill);
      expect(orders.lineShows(_product, '3'), findsOneWidget);
      expect(orders.lineShows(_product, '75.00'), findsOneWidget);
      await orders.leaveBill();
    });
  });

  testWidgets('paying less than the total is refused and nothing is sold',
      (tester) async {
    await _step('refused payment', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      final cart = CartRobot(shell);
      await cart.open();
      await cart.addByBarcode(_stocked.barcode);
      await cart.setQuantity(_product, 3);
      final before = await _bills.beforeSale();

      // Act
      await cart.openPayment(tendered: '50');

      // Assert
      expect(cart.payButton('โปรดระบุยอดที่ต้องชำระ'), findsOneWidget);

      // Act
      await cart.submitPayment();

      // Assert
      await cart.expectRefused('Error: คุณรับเงินน้อยกว่ายอดราคาสินค้า');
      expect(cart.paymentDue('฿75.00'), findsOneWidget,
          reason: 'the payment stays open');
      await cart.closePayment();
      // The payment stayed open for seconds, long enough to be painted.
      expect(quantityKeypadOverflowsSwallowed, greaterThanOrEqualTo(1),
          reason: 'The quantity keypad no longer overflows: drop '
              'onQuantityKeypad and unskip its FINDING test.');
      expect(paymentDisplayOverflowsSwallowed, greaterThanOrEqualTo(1),
          reason: 'The payment display no longer overflows: drop '
              'onPaymentDialog and unskip its FINDING test.');
      await cart.removeLine(_product);
      expect(await billsOfProductSince(_product, before), isEmpty);
      await _expectOnHand(shell, 7);
    });
  });

  testWidgets(
      'a PromptPay sale with a customer and a line discount shows the '
      'discounted total and change', (tester) async {
    await _step('PromptPay sale of 2', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      final customer = await saleCustomer();
      final cart = CartRobot(shell);
      await cart.open();
      await cart.addByBarcode(_stocked.barcode);
      await cart.setQuantity(_product, 2);
      await cart.chooseCustomer(customer.name, code: customer.code);

      // Act: ฿5 off each of the 2
      await cart.setLineDiscountBaht(_product, 5);

      // Assert
      expect(cart.lineShows(_product, '฿50.00'), findsOneWidget,
          reason: 'the price before the discount, struck through');
      expect(cart.lineShows(_product, '฿40.00'), findsOneWidget);
      expect(cart.total(), '฿40.00');
      final before = await _bills.beforeSale();

      // Act
      await cart.openPayment(promptPay: true, tendered: '100');

      // Assert
      expect(cart.paymentDue('฿40.00'), findsOneWidget);
      expect(cart.payButton('เงินทอน ฿60.00'), findsOneWidget);

      // Act
      await cart.submitPayment();

      // Assert
      await cart.expectSold();
      _promptPayBill = await _bills.recordNew(before);
      expect(_promptPayBill.rowTitle, endsWith(' Name: ${customer.name}'));
      await _expectOnHand(shell, 5);
      final orders = OrderRobot(shell);
      await orders.openList();
      expect(await orders.isListed(_promptPayBill), isTrue,
          reason: 'All lists the PromptPay bill');
      await orders.chooseFilter('Store');
      expect(await orders.isListed(_promptPayBill), isFalse,
          reason: 'Store keeps only cash bills');
      expect(await orders.isListed(_cashBill), isTrue);
      await orders.chooseFilter('All');
      await orders.openBill(_promptPayBill);
      expect(orders.lineShows(_product, '2'), findsOneWidget);
      expect(orders.lineShows(_product, '40.00'), findsOneWidget);
      await orders.leaveBill();
    });
  });

  testWidgets('returning 1 piece puts 1 back and marks the line',
      (tester) async {
    await _step('return 1', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      final orders = OrderRobot(shell);
      await orders.openList();
      await orders.openBill(_promptPayBill);

      // Act / Assert: the dialog offers all 2 back at what was paid
      await orders.openReturn(_product);
      expect(orders.returnDialogShows('คืนได้สูงสุด 2'), findsOneWidget);
      expect(orders.returnField('จำนวนที่คืน'), '2');
      expect(orders.returnField('จำนวนเงินคืน'), '40.00');
      await orders.submitReturn(quantity: 1, reason: _returnReason);
      Cleanup.keep('return of 1 on order ${_promptPayBill.code} '
          '(returns cannot be undone)');

      // Assert
      expect(orders.lineShows(_product, 'คืน 1'), findsOneWidget);
      await orders.openReturnHistory();
      expect(orders.historyShows(_returnReason), findsOneWidget);
      expect(orders.historyShows('จำนวน 1, คืนเงิน ฿20.00'), findsOneWidget);
      expect(orders.historyShows('คืนเงินรวม ฿20.00'), findsOneWidget);
      await shell.closeDialog();
      await orders.leaveBill();
      await _expectOnHand(shell, 6);
    });
  });

  testWidgets('cancelling a line then the bill puts the rest back',
      (tester) async {
    await _step('cancel a line, then a bill', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      final orders = OrderRobot(shell);
      await orders.openList();
      await orders.openBill(_promptPayBill);

      // Act: bill 2's line; 1 of its 2 is back already
      await orders.cancelLine(_product);
      await orders.leaveBill();

      // Assert, on the bill opened again: pos-api cancels the line and sets
      // the bill to 0.00 (the list row shows 0.00), but the detail maps no
      // line status and sums the lines itself (FINDING, skipped test below)
      final cancelledLine = await billNow(_promptPayBill.id);
      expect(cancelledLine.totalText, '0.00');
      await orders.openBill(cancelledLine);
      expect(orders.lineShows(_product, '40.00'), findsOneWidget);
      expect(orders.detailShows('฿ 40.00'), findsOneWidget,
          reason: 'the detail currently still counts a cancelled line');
      await orders.leaveBill();

      // Assert
      await _expectOnHand(shell, 7);

      // Act: the whole of bill 1
      await orders.openList();
      await orders.openBill(_cashBill);
      await orders.cancelBill();
      _bills.markCancelled(_cashBill);

      // Assert: pos-api only marks a cancelled bill, total and all, and the
      // app maps no status, so it stays listed unmarked at 75.00 (FINDING,
      // skipped test below); with bill 2 at 0.00 the Total keeps 75.00
      expect(await orders.isListed(_cashBill), isTrue,
          reason: 'the app currently keeps listing a cancelled bill');
      expect((await billNow(_cashBill.id)).totalText, '75.00');
      await _expectOnHand(shell, 10);
    });
  });

  // FINDINGs (Task 7). They read the chain's product and bills, so they
  // run, if unskipped, after it; skipped tests do not sign in or write.

  group('FINDING', () {
    // DELETE /orders/:id marks the bill CANCELLED and keeps its total (pos-api
    // app/data/ledger/cancel.go:23-60); GET /orders returns every status
    // (order.go:105-134); the app maps no status (order_mapper.dart) and
    // lists and sums every bill (order_view_model.dart:41-56).
    testWidgets('a cancelled bill is no longer listed', (tester) async {
      final orders = OrderRobot(await _signedInShell(tester));
      await orders.openList();

      expect(await orders.isListed(_cashBill), isFalse);
    });
  },
      skip: 'FINDING: a cancelled bill stays in รายการขาย and in its Total '
          '(order_view_model.dart:41-56; pos-api order.go:105-134)');

  // DELETE /orders/items/:id marks the line CANCELLED and recomputes the
  // bill (ledger/cancel.go:64-90); GET /orders/:id returns every line
  // (order.go:444-477) and the detail sums them (order_detail_page.dart:386).
  group('FINDING', () {
    testWidgets('a cancelled line no longer counts on the bill',
        (tester) async {
      final orders = OrderRobot(await _signedInShell(tester));
      await orders.openList();
      await orders.openBill(await billNow(_promptPayBill.id));

      expect(orders.detailShows('฿ 0.00'), findsOneWidget);
    });
  },
      skip: 'FINDING: a cancelled line stays on the bill detail and in its '
          'Total (order_detail_page.dart:246-269, 386)');

  // ProductSearch loads in initState only (product_search.dart:41-46); the
  // sale invalidates the product cache but nothing reloads the grid
  // (cart_page.dart:75-81).
  group('FINDING', () {
    testWidgets('after a sale the grid shows the new stock', (tester) async {
      final cart = CartRobot(await _signedInShell(tester));
      await cart.open();
      await cart.addByBarcode(_stocked.barcode);
      final before = await _bills.beforeSale();
      await cart.pay();
      await _bills.recordNew(before);

      expect(cart.tileShows(_product, 'คงเหลือ 9 ชิ้น'), findsOneWidget);
    });
  },
      skip: 'FINDING: the selling grid keeps its stock figures after a sale '
          '(product_search.dart:41-46)');

  // Fixed-height dialogs too low for their Sarabun text: see
  // selling_faults.dart. flutter_test fails these on the overflow.
  group('FINDING', () {
    testWidgets('the quantity and payment dialogs fit their text',
        (tester) async {
      final cart = CartRobot(await _signedInShell(tester));
      await cart.open();
      await cart.addByBarcode(_stocked.barcode);
      await tester.tap(cart.lineShows(_product, '1x'));
      await tester.pump(const Duration(seconds: 1));
      await cart.shell.closeDialog();
      await tester.tap(cart.payButtonInCart);
      await tester.pump(const Duration(seconds: 1));
    });
  },
      skip: 'FINDING: the quantity keypad (decimal_input.dart:103) and the '
          'payment display (payment_screen.dart:221) overflow');
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

/// The product list shows [quantity] on hand for the run's product.
Future<void> _expectOnHand(ShellRobot shell, int quantity) async {
  final products = ProductRobot(shell);
  await products.openList();
  await products.expectStockOnHand(_product, quantity, unit: _stocked.unit);
}
