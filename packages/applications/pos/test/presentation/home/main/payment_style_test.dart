// The payment dialog in the redesign's look: the chosen method is filled,
// the other is outlined; boxes and the pay button take the card radius.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/payment_screen.dart';
import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';

Future<void> _open(WidgetTester tester, Size size, {bool dark = false}) async {
  useViewSize(tester, size);
  await tester.pumpWidget(MaterialApp(
    theme: dark ? CustomTheme.darkTheme : CustomTheme.mainTheme,
    localizationsDelegates: const [thaiLanguages],
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showPaymentDialog(context,
              amount: 50, onCompleted: (_, __) {}, onError: () {}),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The decorated box drawn around the method named [title].
BoxDecoration _option(WidgetTester tester, String title) => tester
    .widget<Container>(find
        .ancestor(of: find.text(title), matching: find.byType(Container))
        .first)
    .decoration! as BoxDecoration;

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  setUpAll(loadAppFonts);

  for (final size in [phoneSize, desktopSize]) {
    for (final dark in [false, true]) {
      final colors = dark ? AppColors.dark : AppColors.light;
      testWidgets(
          'the chosen method is filled and the other outlined '
          '($size, dark=$dark)', (tester) async {
        await _open(tester, size, dark: dark);

        final cash = _option(tester, 'เงินสด');
        final promptPay = _option(tester, 'พร้อมเพย์');
        expect(cash.color, colors.primaryFill);
        expect(_textColor(tester, 'เงินสด'), colors.onPrimaryFill);
        expect(promptPay.color, colors.surfaceRaised);
        expect(promptPay.border, Border.all(color: colors.border));
        expect(_textColor(tester, 'พร้อมเพย์'), colors.textPrimary);
        expect(cash.borderRadius, BorderRadius.circular(AppRadius.card));

        await tester.tap(find.text('พร้อมเพย์'));
        await tester.pumpAndSettle();

        expect(_option(tester, 'พร้อมเพย์').color, colors.primaryFill);
        expect(_option(tester, 'เงินสด').color, colors.surfaceRaised);
      });
    }

    testWidgets('the amount boxes and the pay button take the card radius '
        '($size)', (tester) async {
      await _open(tester, size);

      for (final title in ['ยอดรับเงินรวม', 'เงินทอน']) {
        final box = tester
            .widget<Container>(find
                .ancestor(of: find.text(title), matching: find.byType(Container))
                .first)
            .decoration! as BoxDecoration;
        expect(box.borderRadius, BorderRadius.circular(AppRadius.card),
            reason: title);
      }
      final pay = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(pay.style?.shape?.resolve({}),
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card)));
      expect(pay.style?.backgroundColor?.resolve({}),
          AppColors.light.primaryFill);
    });
  }
}
