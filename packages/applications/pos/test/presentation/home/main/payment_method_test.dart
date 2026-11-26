// The payment dialog's method: a PromptPay payment is always for exactly the
// total (a QR payment has no tender and no change), and on a phone the
// method is chosen where it is seen, under the dialog's title.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/payment_screen.dart';
import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';

/// What the dialog paid: the amount and the method.
typedef _Paid = (double, String);

Future<List<_Paid>> _open(WidgetTester tester,
    {double amount = 50, Size size = phoneSize}) async {
  useViewSize(tester, size);
  final paid = <_Paid>[];
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: const [thaiLanguages],
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showPaymentDialog(context,
              amount: amount,
              onCompleted: (amount, type) => paid.add((amount, type)),
              onError: () {}),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return paid;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, String digit) =>
    _tap(tester, find.byKey(Key('btn_$digit')));

Future<void> _pay(WidgetTester tester) =>
    _tap(tester, find.byType(ElevatedButton));

/// The box titled [title] (ยอดรับเงินรวม, เงินทอน).
Finder _box(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(Container)).first;

void main() {
  setUpAll(loadAppFonts);

  group('PromptPay', () {
    testWidgets('after a chip, PromptPay pays exactly the total',
        (tester) async {
      // Arrange
      final paid = await _open(tester);
      await _tap(tester, find.text('฿100'));

      // Act
      await _tap(tester, find.text('พร้อมเพย์'));
      await _pay(tester);

      // Assert
      expect(paid, [(50.0, 'PromptPay')]);
    });

    testWidgets('after digits, PromptPay shows no amount received or change',
        (tester) async {
      // Arrange
      await _open(tester);
      for (final digit in ['1', '0', '0']) {
        await _key(tester, digit);
      }

      // Act
      await _tap(tester, find.text('พร้อมเพย์'));

      // Assert
      expect(
          find.descendant(of: _box('เงินทอน'), matching: find.text('฿50.00')),
          findsNothing);
      expect(
          find.descendant(
              of: _box('ยอดรับเงินรวม'), matching: find.text('฿100')),
          findsNothing);
      expect(find.textContaining('เงินทอน ฿'), findsNothing,
          reason: 'the pay button never offers change for PromptPay');
    });

    testWidgets('back to cash, the chips return and nothing is entered',
        (tester) async {
      // Arrange
      final paid = await _open(tester);
      await _tap(tester, find.text('฿100'));
      await _tap(tester, find.text('พร้อมเพย์'));

      // Act
      await _tap(tester, find.text('เงินสด'));
      await _pay(tester);

      // Assert
      expect(find.text('฿100'), findsOneWidget, reason: 'the chip is back');
      expect(paid, [(50.0, 'Cash')], reason: 'nothing was pre-entered');
    });

    testWidgets('a digit after a chip pays the typed amount', (tester) async {
      // Arrange
      final paid = await _open(tester);
      await _tap(tester, find.text('฿100'));

      // Act
      for (final digit in ['7', '0']) {
        await _key(tester, digit);
      }
      await _pay(tester);

      // Assert
      expect(paid, [(70.0, 'Cash')]);
    });
  });
}
