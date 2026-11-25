// A product of the run's own is renamed and repriced, and the selling
// screen shows it; then it is deleted through its edit page and its barcode
// no longer sells. Run with tools/e2e/run.sh <local|hosted>
// product_edit_test.dart.
//
// The two tests are one ordered chain sharing the run's product. The
// second deletes it on screen, so the clean-up registered for both of its
// names finds nothing left to delete. Everything touched is the run's own
// product, its receipt and the kept "E2E supplier", so the hosted target
// runs all of it.

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'support/api/product_api.dart';
import 'support/app.dart';
import 'support/fixtures.dart';
import 'support/robots/cart_robot.dart';
import 'support/robots/product_edit_robot.dart';
import 'support/robots/product_robot.dart';
import 'support/robots/shell_robot.dart';
import 'support/run_data.dart';
import 'support/stock_plan.dart';

const _general = 'ลูกค้าทั่วไป';
const _wholesale = 'ลูกค้าขายส่ง';
const _newGeneralPrice = 30.0;
const _wholesalePrice = 20.0;

final _product = RunData.name('edit product');
final _renamed = '$_product renamed';
final _chain = StepChain();

late StockedProduct _stocked;

void main() {
  initE2E();

  setUpAll(() {
    // The product carries one name or the other, whichever step it reached.
    deleteProductAfterFile(_product);
    deleteProductAfterFile(_renamed);
  });

  testWidgets(
      "a product's price and name can be changed and the selling screen "
      'shows them', (tester) async {
    await _step('rename and reprice', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      _stocked =
          await stockProduct(shell, what: 'edit product', barcodeNumber: 7);
      final products = ProductRobot(shell);
      final edit = ProductEditRobot(products);
      await products.open(_product);

      // Act
      await edit.rename(_renamed);

      // Assert: the detail and the list carry the new name
      expect(edit.detailTitle(_renamed), findsOneWidget);
      expect(await products.isListed(_renamed), isTrue);
      expect(await products.isListed(_product), isFalse);
      await products.open(_renamed);

      // Act: the General price 25 → 30, and a wholesale price of 20
      await products.openTab('ราคา');
      await edit.changePrice(_general, _newGeneralPrice);
      await edit.addPrice(_wholesale, _wholesalePrice);

      // Assert: the price tab lists both
      expect(edit.priceRow(_general, '฿30.00'), findsOneWidget);
      expect(edit.priceRow(_wholesale, '฿20.00'), findsOneWidget);
      expect(edit.priceTabShows('฿25.00'), findsNothing);

      // Assert: the selling screen shows the new name at the General price;
      // a wholesale price applies only once a wholesale customer is chosen
      // (OrderItem prices by the sale's customer type, order_item.dart:63).
      await _expectSellsAs(shell, '฿30.00');
    });
  });

  testWidgets('a product can be deleted and no longer sells', (tester) async {
    await _step('delete the product', () async {
      // Arrange
      final shell = await _signedInShell(tester);
      final products = ProductRobot(shell);
      await products.openList();
      await products.open(_renamed);

      // Act
      await products.delete();

      // Assert: gone from the list and the server
      expect(await products.isListed(_renamed), isFalse);
      expect(await productsNamed(_renamed), isEmpty);

      // Assert: its barcode no longer sells
      final cart = CartRobot(shell);
      await cart.open();
      await cart.addByBarcode(_stocked.barcode, found: false);
      await shell.expectSnackbar('Error: ไม่พบสินค้า');
      await shell.waitForSnackbarToClose();
      expect(cart.isEmpty, isTrue);
    });
  });
}

/// On the selling screen: the grid tile and a scanned line show the renamed
/// product at [price]; the line is taken off again.
Future<void> _expectSellsAs(ShellRobot shell, String price) async {
  final cart = CartRobot(shell);
  await cart.open();
  expect(cart.tileShows(_renamed, price), findsOneWidget);
  expect(cart.tileShows(_renamed, '฿20.00'), findsNothing,
      reason: 'the grid shows the General price');

  await cart.addByBarcode(_stocked.barcode);
  expect(cart.line(_renamed), findsOneWidget);
  expect(cart.lineShows(_renamed, price), findsOneWidget);
  await cart.removeLine(_renamed);
  expect(cart.isEmpty, isTrue);
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
