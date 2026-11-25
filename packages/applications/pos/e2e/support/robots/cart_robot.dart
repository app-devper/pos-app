// The selling screen ("ขายสินค้า") on a wide screen: the product grid with
// its search field, the cart of the open slot, the customer picker, the
// quantity and line dialogs, and the payment dialog.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/decimal_input.dart';
import 'package:design_system/widgets/title_bar.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/cart_widget.dart';
import 'package:pos/presentation/home/main/payment_screen.dart';
import 'package:pos/presentation/home/main/product_search.dart';
import '../pump.dart';
import '../selling_faults.dart';
import 'shell_robot.dart';

const _searchHint = 'ค้นหาชื่อสินค้า หรือสแกนบาร์โค้ด';
const _emptyCart = 'เลือกสินค้าเพื่อเริ่มขาย';
const _sold = 'Order success';

final _grid = find.byType(ProductSearch);
final _payment = find.byType(PaymentScreen);
final _keypad = find.byType(DecimalInput);
final _loading = find.text('กำลังโหลด...');

class CartRobot {
  CartRobot(this.shell);

  final ShellRobot shell;

  WidgetTester get tester => shell.tester;

  /// From anywhere in the shell: the sidebar's ขายสินค้า, until the grid
  /// has loaded without an error. The cart must be empty: the slots are a
  /// singleton and outlive the screen.
  Future<void> open() async {
    await shell.openSelling();
    await shell.expectScreenWithoutError(shell.searchField(_searchHint));
    await pumpUntilGone(tester,
        find.descendant(of: _grid, matching: find.byType(ProgressIndicator)));
    expect(isEmpty, isTrue, reason: 'the cart should start empty');
  }

  /// Types [code] into the search field and presses Enter, which the screen
  /// takes as a scanned barcode. With [found] it waits for the line.
  Future<void> addByBarcode(String code, {bool found = true}) async {
    final field = shell.searchField(_searchHint);
    await tester.enterText(field, code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await pumpUntilGone(tester, _loading);
    if (found) await pumpUntilFound(tester, _lines.hitTestable());
  }

  Finder get _lines => find.byType(CartOrderItem);

  /// The cart line of [productName].
  Finder line(String productName) => find
      .byWidgetPredicate((w) => w is CartOrderItem && w.title == productName)
      .hitTestable();

  /// [text] (exactly) on [productName]'s cart line, e.g. `3x` or `฿75.00`.
  Finder lineShows(String productName, String text) =>
      find.descendant(of: line(productName), matching: find.text(text));

  bool get isEmpty =>
      _lines.evaluate().isEmpty &&
      find.text(_emptyCart).hitTestable().evaluate().isNotEmpty;

  /// 'ยอดรวมสุทธิ' as the cart prints it, e.g. `฿75.00`.
  String total() {
    final tile = find.widgetWithText(ListTile, 'ยอดรวมสุทธิ').hitTestable();
    final trailing = (tester.widget<ListTile>(tile).trailing as Text?)?.data;
    return trailing ?? '';
  }

  /// Taps the line's `<n>x` and keys [quantity] in the 'จำนวนสินค้า'
  /// keypad dialog.
  /// The dialog's display overflows (a known finding), let through here.
  Future<void> setQuantity(String productName, int quantity) =>
      onQuantityKeypad(() => _setQuantity(productName, quantity));

  Future<void> _setQuantity(String productName, int quantity) async {
    final current = tester.widget<CartOrderItem>(line(productName)).quantity;
    await tester.tap(lineShows(productName, '${current}x'));
    await tester.pump();
    await pumpUntilFound(tester, _keypad.hitTestable());
    await _keyIn(_keypad, '$quantity');
    await shell.tapTitleBarAction('ยืนยัน');
    await pumpUntilGone(tester, _keypad);
    await pumpUntilFound(tester, lineShows(productName, '${quantity}x'));
  }

  /// Opens the line dialog (the line's title) and types [amount] baht off
  /// each unit.
  Future<void> setLineDiscountBaht(String productName, num amount) async {
    await _openLineDialog(productName);
    final field = find.descendant(
        of: find.widgetWithText(ListTile, 'ส่วนลดสินค้า (฿)'),
        matching: find.byType(TextField));
    await tester.enterText(field.hitTestable(), '$amount');
    await tester.pump();
    await shell.tapTitleBarAction('ยืนยัน');
    await pumpUntilGone(tester, _lineDialog);
  }

  /// The line dialog's red 'ยกเลิกสินค้า' takes the line off the sale.
  Future<void> removeLine(String productName) async {
    await _openLineDialog(productName);
    await tester.tap(find.text('ยกเลิกสินค้า').hitTestable());
    await tester.pump();
    await pumpUntilGone(tester, _lineDialog);
    await pumpUntilGone(tester, line(productName));
  }

  Finder get _lineDialog => find.text('ส่วนลดสินค้า (฿)');

  Future<void> _openLineDialog(String productName) async {
    await tester.tap(find.descendant(
        of: line(productName), matching: find.text(productName)));
    await tester.pump();
    await pumpUntilFound(tester, _lineDialog.hitTestable());
  }

  /// The customer tile opens 'เลือกลูกค้า'; searches for [name] and picks
  /// the row with [code].
  Future<void> chooseCustomer(String name, {required String code}) async {
    await tester.tap(find.text('ข้อมูลลูกค้า').hitTestable());
    await tester.pump();
    final picker = find.ancestor(
        of: find.text('เลือกลูกค้า').hitTestable(),
        matching: find.byType(TitleBar));
    await pumpUntilFound(tester, picker);
    final search = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'ค้นหา...');
    await tester.enterText(search.hitTestable(), name);
    await tester.pump();
    final row = find.byWidgetPredicate((w) =>
        w is ListTile &&
        (w.title as Text?)?.data == name &&
        (w.subtitle as Text?)?.data == code);
    await pumpUntilFound(tester, row.hitTestable());
    await tester.tap(row.hitTestable());
    await tester.pump();
    await pumpUntilGone(tester, search);
    await pumpUntilFound(tester, find.text(code).hitTestable());
  }

  // --- Payment --------------------------------------------------------------

  /// Presses 'ชำระเงิน (n รายการ)'; picks พร้อมเพย์ when [promptPay] and
  /// keys in [tendered] when given (else the exact amount is taken).
  /// Its amount display overflows (a known finding), let through here.
  Future<void> openPayment({bool promptPay = false, String? tendered}) =>
      onPaymentDialog(
          () => _openPayment(promptPay: promptPay, tendered: tendered));

  /// The cart's 'ชำระเงิน (n รายการ)' button.
  Finder get payButtonInCart => find
      .ancestor(
          of: find.textContaining('ชำระเงิน ('),
          matching: find.byType(ElevatedButton))
      .hitTestable();

  Future<void> _openPayment({required bool promptPay, String? tendered}) async {
    await tester.tap(payButtonInCart);
    await tester.pump();
    await pumpUntilFound(tester, _payment.hitTestable());
    if (promptPay) {
      await tester.tap(_inPayment(find.text('พร้อมเพย์')));
      await tester.pump();
    }
    if (tendered != null) await _keyIn(_payment, tendered);
  }

  /// 'ยอดที่ต้องชำระ' showing [amount], e.g. `฿75.00`.
  Finder paymentDue(String amount) => find
      .descendant(
          // The nearest Column holds just the label and the amount.
          of: find
              .ancestor(
                  of: find.text('ยอดที่ต้องชำระ'),
                  matching: find.byType(Column))
              .first,
          matching: find.text(amount))
      .hitTestable();

  /// The payment dialog's one ElevatedButton, labelled [label].
  Finder payButton(String label) =>
      _inPayment(find.widgetWithText(ElevatedButton, label));

  // Every step that pumps while the payment dialog is open lets its known
  // overflow through: it is reported again whenever the display relays out.

  Future<void> submitPayment() => onPaymentDialog(() async {
        await tester.tap(_inPayment(find.byType(ElevatedButton)));
        await tester.pump();
      });

  /// A refused payment: the error snackbar [text] shows over the open
  /// payment, then closes on its own.
  Future<void> expectRefused(String text) => onPaymentDialog(() async {
        await shell.expectSnackbar(text);
        await shell.waitForSnackbarToClose();
      });

  Future<void> closePayment() => onPaymentDialog(() async {
        await shell.closeDialog();
        await pumpUntilGone(tester, _payment);
      });

  /// "Order success" shows, the payment closes and the cart is empty. The
  /// snackbar never closes on its own (a known finding), so it is cleared
  /// the way a user would.
  Future<void> expectSold() async {
    await onPaymentDialog(() async {
      await pumpUntilFound(tester, find.text(_sold).hitTestable(),
          timeout: const Duration(seconds: 30));
      await pumpUntilGone(tester, _payment);
    });
    expect(isEmpty, isTrue, reason: 'a sold cart is emptied');
    await tester.tap(find.text('Clear').hitTestable());
    await tester.pump();
    await shell.waitForSnackbarToClose();
  }

  /// Opens the payment, takes [tendered] (or the exact amount) and waits
  /// for the sale.
  Future<void> pay({bool promptPay = false, String? tendered}) async {
    await openPayment(promptPay: promptPay, tendered: tendered);
    await submitPayment();
    await expectSold();
  }

  /// The grid tile of [productName] showing [text], e.g. `คงเหลือ 7 ชิ้น`.
  Finder tileShows(String productName, String text) => find
      .descendant(
          of: find.ancestor(
              of: find.descendant(of: _grid, matching: find.text(productName)),
              matching: find.byType(ProductItem)),
          matching: find.text(text))
      .hitTestable();

  Finder _inPayment(Finder finder) =>
      find.descendant(of: _payment, matching: finder).hitTestable();

  /// Taps the keypad keys `btn_<c>` under [pad] for each character.
  Future<void> _keyIn(Finder pad, String digits) async {
    for (final c in digits.split('')) {
      await tester.tap(find
          .descendant(of: pad, matching: find.byKey(Key('btn_$c')))
          .hitTestable());
      await tester.pump();
    }
  }
}
