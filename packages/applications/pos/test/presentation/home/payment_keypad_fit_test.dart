// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/payment_screen.dart';
import '../../support/app_languages.dart';

/// The smallest a keypad key may be: a finger's target.
const _minKeyHeight = 48.0;

const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'];

Future<void> _openPayment(WidgetTester tester, Size screen,
    {double amount = 1234.50}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: const [thaiLanguages],
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showPaymentDialog(context,
              amount: amount, onCompleted: (_, __) {}, onError: () {}),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Sarabun')
      ..addFont(
          rootBundle.load('packages/common/assets/font/Sarabun-Regular.ttf'));
    await loader.load();
  });

  for (final amount in [1234.50, 85.0]) {
    testWidgets(
        'on a 360x640 phone every keypad key is above the pay button, '
        'nothing to scroll (total $amount)', (tester) async {
      // Arrange / Act
      await _openPayment(tester, const Size(360, 640), amount: amount);

      // Assert
      final payTop = tester.getRect(find.byType(ElevatedButton)).top;
      for (final key in _keys) {
        final rect = tester.getRect(find.byKey(Key('btn_$key')));
        expect(rect.bottom, lessThanOrEqualTo(payTop),
            reason: 'key $key is under the pay button');
        expect(rect.height, greaterThanOrEqualTo(_minKeyHeight),
            reason: 'key $key is too low to tap');
      }
      final chipTops = tester
          .widgetList(find.byType(OutlinedButton))
          .map((chip) => tester.getRect(find.byWidget(chip)).top)
          .toSet();
      expect(chipTops, hasLength(1), reason: 'the chips share one row');
      final scroll = tester.state<ScrollableState>(find
          .descendant(
              of: find.byType(PaymentScreen), matching: find.byType(Scrollable))
          .first);
      expect(scroll.position.maxScrollExtent, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('on a tall phone the keypad keeps its full height',
      (tester) async {
    // Arrange / Act
    await _openPayment(tester, const Size(390, 844));

    // Assert
    final first = tester.getRect(find.byKey(const Key('btn_1')));
    final last = tester.getRect(find.byKey(const Key('btn_0')));
    expect(last.bottom - first.top, greaterThanOrEqualTo(240));
  });
}
