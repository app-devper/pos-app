// The cart's payment dialog as the cart opens it, laid out in the app's
// fonts at a phone's and a desktop's size.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/payment_screen.dart';
import '../../../support/app_fonts.dart';

Widget _host() => MaterialApp(
      theme: CustomTheme.mainTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPaymentDialog(context,
                amount: 1234.5, onCompleted: (_, __) {}, onError: () {}),
            child: const Text('open'),
          ),
        ),
      ),
    );

/// The display box titled 'ยอดรับเงินรวม'.
final _display = find
    .ancestor(of: find.text('ยอดรับเงินรวม'), matching: find.byType(Container))
    .first;

void main() {
  setUpAll(loadAppFonts);

  for (final size in [phoneSize, desktopSize]) {
    testWidgets(
        'the payment dialog shows the tendered amount whole, '
        'without overflow, $size', (tester) async {
      // Arrange
      useViewSize(tester, size);
      await tester.pumpWidget(_host());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Act
      for (final digit in ['2', '0', '0', '0']) {
        await tester.tap(find.byKey(Key('btn_$digit')));
        await tester.pump();
      }

      // Assert
      expect(tester.takeException(), isNull);
      expectInside(tester, find.text('ยอดรับเงินรวม'), _display);
      expectInside(tester, find.text('฿2,000'), _display);
      final due = find.text('฿1,234.50');
      expectInside(tester, due,
          find.ancestor(of: due, matching: find.byType(Container)).first);
    });
  }
}
