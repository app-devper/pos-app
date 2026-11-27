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
import '../../../support/app_languages.dart';

Widget _host(
        {void Function(double, String)? onCompleted,
        double amount = 1234.5,
        bool dark = false}) =>
    MaterialApp(
      theme: dark ? CustomTheme.darkTheme : CustomTheme.mainTheme,
      localizationsDelegates: const [thaiLanguages],
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPaymentDialog(context,
                amount: amount,
                onCompleted: onCompleted ?? (_, __) {},
                onError: () {}),
            child: const Text('open'),
          ),
        ),
      ),
    );

/// The display box titled 'ยอดรับเงินรวม'.
final _display = find
    .ancestor(of: find.text('ยอดรับเงินรวม'), matching: find.byType(Container))
    .first;

/// Taps the keypad's [digit], scrolled into view first: on a phone the
/// dialog's body scrolls under its pinned pay button.
Future<void> _tapKey(WidgetTester tester, String digit) async {
  final key = find.byKey(Key('btn_$digit'));
  await tester.ensureVisible(key);
  await tester.pumpAndSettle();
  await tester.tap(key);
  await tester.pump();
}

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
        await _tapKey(tester, digit);
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

  for (final size in [phoneSize, desktopSize]) {
    testWidgets(
        'the payment dialog fits its amounts at a larger system text size, '
        '$size', (tester) async {
      // Arrange
      useViewSize(tester, size);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_host());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Act
      for (final digit in ['2', '0', '0', '0']) {
        await _tapKey(tester, digit);
      }

      // Assert
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('on a phone the pay button can be scrolled to and pressed',
      (tester) async {
    // Arrange
    useViewSize(tester, phoneSize);
    final paid = <double>[];
    await tester
        .pumpWidget(_host(onCompleted: (amount, _) => paid.add(amount)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final pay = find.ancestor(
        of: find.bySemanticsLabel('รับชำระพอดี ไม่มีเงินทอน'),
        matching: find.byType(ElevatedButton));

    // Act
    await tester.ensureVisible(pay);
    await tester.pumpAndSettle();
    await tester.tap(pay);
    await tester.pump();

    // Assert
    expect(tester.takeException(), isNull);
    expect(paid, [1234.5]);
  });

  group('quick cash', () {
    Future<void> open(WidgetTester tester,
        {double amount = 50, bool dark = false}) async {
      await tester.pumpWidget(_host(amount: amount, dark: dark));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('cash offers a chip per quick-cash amount, each named',
        (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);

      // Act
      await open(tester);

      // Assert
      for (final label in ['฿60', '฿100', '฿500', '฿1,000']) {
        expect(find.text(label), findsOneWidget, reason: label);
        expect(find.bySemanticsLabel('รับเงิน $label'), findsOneWidget,
            reason: label);
      }
    });

    testWidgets('PromptPay offers no quick-cash chips', (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);
      await open(tester);

      // Act
      await tester.ensureVisible(find.text('พร้อมเพย์'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('พร้อมเพย์'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('฿100'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^รับเงิน ')), findsNothing);
    });

    testWidgets('tapping ฿100 on a 50 total receives 100 and shows 50 change',
        (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);
      final paid = <double>[];
      await tester.pumpWidget(
          _host(amount: 50, onCompleted: (amount, _) => paid.add(amount)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('฿100'));
      await tester.pumpAndSettle();

      // Assert
      final change = find.ancestor(
          of: find.text('เงินทอน'), matching: find.byType(Container));
      expect(find.descendant(of: change.first, matching: find.text('฿50.00')),
          findsOneWidget);
      expect(find.descendant(of: _display, matching: find.text('฿100')),
          findsOneWidget,
          reason: 'the received amount shows 100');
      final pay = find.byType(ElevatedButton);
      await tester.ensureVisible(pay);
      await tester.pumpAndSettle();
      await tester.tap(pay);
      await tester.pump();
      expect(paid, [100]);
    });

    testWidgets('after a chip the keypad starts a new amount', (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);
      await open(tester);
      await tester.tap(find.text('฿100'));
      await tester.pumpAndSettle();

      // Act
      for (final digit in ['7', '0']) {
        await _tapKey(tester, digit);
      }

      // Assert
      expect(find.text('฿70'), findsOneWidget);
    });

    testWidgets('on a 360 px phone the four chips share one row',
        (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);

      // Act
      await open(tester);

      // Assert
      final tops = {
        for (final label in ['฿60', '฿100', '฿500', '฿1,000'])
          // The chip, not its label: an amount shrunk to fit sits a
          // pixel lower in its chip.
          tester
              .getRect(find.ancestor(
                  of: find.text(label), matching: find.byType(OutlinedButton)))
              .top
              .round()
      };
      expect(tops, hasLength(1), reason: 'the keypad stays in view below');
    });

    for (final size in [phoneSize, desktopSize]) {
      testWidgets('the chips are 48 high and 8 apart, $size', (tester) async {
        // Arrange
        useViewSize(tester, size);

        // Act
        await open(tester);

        // Assert
        final rects = [
          for (final label in ['฿60', '฿100', '฿500', '฿1,000'])
            tester.getRect(find.ancestor(
                of: find.text(label), matching: find.byType(OutlinedButton)))
        ];
        for (final rect in rects) {
          expect(rect.height, greaterThanOrEqualTo(48));
        }
        for (var i = 1; i < rects.length; i++) {
          final previous = rects[i - 1];
          final current = rects[i];
          final sameRow = (current.top - previous.top).abs() < 1;
          final gap = sameRow
              ? current.left - previous.right
              : current.top - previous.bottom;
          expect(gap, greaterThanOrEqualTo(8), reason: '$previous $current');
        }
      });
    }

    for (final dark in [false, true]) {
      testWidgets('with chips the dialog fits 320 px at 1.3× text, dark=$dark',
          (tester) async {
        // Arrange
        useViewSize(tester, const Size(320, 640));
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        // Act
        await open(tester, amount: 1234.5, dark: dark);

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('฿1,240'), findsOneWidget);
      });
    }
  });

  group('the exact-payment button', () {
    for (final size in [phoneSize, const Size(320, 640), desktopSize]) {
      testWidgets('reads รับชำระพอดี on one centred line, named in full, $size',
          (tester) async {
        // Arrange
        useViewSize(tester, size);

        // Act
        await tester.pumpWidget(_host());
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Assert
        expect(tester.takeException(), isNull);
        final button = find.byType(ElevatedButton);
        expect(
            find.descendant(
                of: button,
                matching: find.bySemanticsLabel('รับชำระพอดี ไม่มีเงินทอน')),
            findsOneWidget);
        final line =
            find.descendant(of: button, matching: find.text('รับชำระพอดี'));
        expect(line, findsOneWidget);
        final lineRect = tester.getRect(line);
        final buttonRect = tester.getRect(button);
        expect(lineRect.height, lessThan(48), reason: 'one line, not wrapped');
        expect((lineRect.center.dx - buttonRect.center.dx).abs(), lessThan(1),
            reason: 'centred');
      });
    }
  });

  group('the pay button', () {
    for (final size in [phoneSize, landscapePhoneSize]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
            'is in view without scrolling, the body scrolls above it, '
            '$size at ${scale}x', (tester) async {
          // Arrange
          useViewSize(tester, size);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final paid = <double>[];
          await tester.pumpWidget(
              _host(amount: 50, onCompleted: (amount, _) => paid.add(amount)));
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          final pay = find.byType(ElevatedButton);

          // Act: tapped where it is, with no scrolling
          final rect = tester.getRect(pay);
          await tester.tap(pay.hitTestable());
          await tester.pump();

          // Assert
          expect(tester.takeException(), isNull);
          expect(
              Offset.zero & size,
              predicate<Rect>((s) =>
                  s.contains(rect.topLeft) &&
                  s.contains(rect.bottomRight - const Offset(0.01, 0.01))));
          expect(paid, [50]);
          await tester.drag(
              find.byType(SingleChildScrollView), const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.getRect(pay), rect,
              reason: 'the button stays put while the body scrolls');
        });
      }
    }
  });

  testWidgets('the amounts use tabular figures', (tester) async {
    // Arrange
    useViewSize(tester, desktopSize);
    await tester.pumpWidget(_host(amount: 50));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('฿100'));
    await tester.pumpAndSettle();

    // Assert: received, due, change, chips and the pay button
    for (final amount in ['฿100', '฿50.00', 'เงินทอน ฿50.00', '฿1,000']) {
      for (final text in tester.widgetList<Text>(find.text(amount))) {
        expect(text.style?.fontFeatures,
            contains(const FontFeature.tabularFigures()),
            reason: amount);
      }
    }
    expect(find.text('฿50.00'), findsNWidgets(2), reason: 'due and change');
  });
}
