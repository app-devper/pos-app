// Ready-made starting points built through the screens, for files whose
// tests need "a product with stock" rather than test making one.
//
// A later file stocks its own product, e.g. in its first test:
//
//   setUpAll(() => deleteProductAfterFile(RunData.name('sale product')));
//   ...
//   final stocked = await stockProduct(shell,
//       what: 'sale product', barcodeNumber: 2);   // 10 at 25, cost 10
//
// [what] and [barcodeNumber] must differ between files: run-all.sh gives
// every file the same run id.

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'api/product_api.dart';
import 'api/receive_api.dart';
import 'cleanup.dart';
import 'env.dart';
import 'known_faults.dart';
import 'robots/product_robot.dart';
import 'robots/receive_robot.dart';
import 'robots/shell_robot.dart';
import 'run_data.dart';
import 'stock_plan.dart';

/// A receipt of one line.
class Receipt {
  const Receipt({
    required this.supplierName,
    required this.reference,
    required this.item,
  });

  final String supplierName;
  final String reference;
  final ReceiptItem item;
}

/// What [stockProduct] made.
class StockedProduct {
  const StockedProduct({
    required this.name,
    required this.barcode,
    required this.unit,
    required this.price,
    required this.cost,
    required this.quantity,
    required this.lot,
    required this.expiry,
    required this.receiveCode,
  });

  final String name;
  final String barcode;
  final String unit;
  final double price;
  final double cost;
  final int quantity;

  /// `L<run id>`, the lot the stock was received under.
  final String lot;

  /// YYYY-MM-DD.
  final String expiry;
  final String receiveCode;
}

/// Call from setUpAll: the product named [name] is deleted after the
/// file's last test (through its repository), whether or not it was made.
///
/// Registered from setUpAll, the cleanup runs once at the end of the file,
/// and so does every undo the file's tests add after it (the ledger keeps
/// one tear-down while one is pending); that suits a file of tests that
/// share the product.
///
/// Its stock is brought to 0 first (see [deleteProductsNamed]); those
/// adjustments cannot be deleted, so they are reported as kept.
void deleteProductAfterFile(String name) =>
    Cleanup.add('product "$name"', () async {
      final zeroed = await deleteProductsNamed(name);
      if (zeroed > 0) {
        Cleanup.keep('$zeroed stock-zeroing adjustment(s) of "$name" '
            '(made before deleting it; cannot be deleted)');
      }
    });

/// From the receipt list: creates [receipt], adds its line, imports it and
/// goes back to the list; returns the receipt's code. The imported receipt and the supplier cannot
/// be deleted, so both are reported as kept. The supplier picker's known
/// overflow is let through meanwhile.
Future<String> receiveAndImport(ReceiveRobot receives, Receipt receipt) =>
    onReceiptPage(() => _receiveAndImport(receives, receipt));

Future<String> _receiveAndImport(ReceiveRobot receives, Receipt receipt) async {
  Cleanup.add('draft receive ${receipt.reference}',
      () => cancelDraftReceivesWithReference(receipt.reference));
  Cleanup.keep('supplier "${receipt.supplierName}" (kept for reuse)');
  await receives.create(
      supplierName: receipt.supplierName, reference: receipt.reference);
  await receives.addItem(receipt.item);
  final code = await receiveCodeFor(receipt.reference);
  await receives.import();
  Cleanup.keep('receive $code (imported, cannot be deleted)');
  Cleanup.keep(
      'stock, history and adjustments of "${receipt.item.productName}" '
      '(pos-api keeps them when the product is deleted)');
  await receives.expectImported();
  await receives.leave();
  return code;
}

/// Signed in as admin: adds the product `RunData.name(what)` with barcode
/// `RunData.barcode(barcodeNumber)`, receives [quantity] of it under lot
/// `L<run id>` with an expiry a year ahead, imports the receipt and checks
/// the product list shows [quantity] on hand. Leaves the app on the product
/// list. The caller registers [deleteProductAfterFile] for the name.
Future<StockedProduct> stockProduct(
  ShellRobot shell, {
  required String what,
  required int barcodeNumber,
  int quantity = 10,
  double price = 25,
  double cost = 10,
  String unit = 'ชิ้น',
}) async {
  final product = NewProduct(
    name: RunData.name(what),
    barcode: RunData.barcode(barcodeNumber),
    unit: unit,
    price: price,
    cost: cost,
  );
  final products = ProductRobot(shell);
  await products.openList();
  await products.add(product);

  final receipt = _receiptOf(product, what: what, quantity: quantity);
  final receives = ReceiveRobot(shell);
  await receives.openList();
  final code = await receiveAndImport(receives, receipt);

  await products.openList();
  await products.expectStockOnHand(product.name, quantity, unit: unit);
  expect(await productsNamed(product.name), hasLength(1));
  return StockedProduct(
    name: product.name,
    barcode: product.barcode,
    unit: unit,
    price: price,
    cost: cost,
    quantity: quantity,
    lot: receipt.item.lot,
    expiry: receipt.item.expiry,
    receiveCode: code,
  );
}

/// One line of [quantity] of [product] at its cost, under lot `L<run id>`
/// expiring a year ahead, from the kept supplier.
Receipt _receiptOf(NewProduct product,
        {required String what, required int quantity}) =>
    Receipt(
      supplierName: keptSupplierName,
      reference: '${E2EEnv.runId} $what',
      item: ReceiptItem(
        productName: product.name,
        quantity: quantity,
        cost: product.cost,
        lot: runLot(E2EEnv.runId),
        expiry: expiryOneYearAfter(DateTime.now()),
      ),
    );
