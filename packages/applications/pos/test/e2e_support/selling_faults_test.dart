// The tolerances are checked against overflows the real widgets raise, laid
// out at the sizes the app's dialogs give them and drawn in the app's font,
// so the reports have the shape the e2e run sees.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/payment_screen.dart';
import '../../e2e/support/selling_faults.dart';

/// The payment dialog is 640 x 600; its TitleBar and divider take 49.
const _paymentBox = Size(640, 551);

/// Too low for the payment screen's outer Column (payment_screen.dart:38).
const _crampedPaymentBox = Size(640, 300);

const _fonts = [
  'packages/common/assets/font/Sarabun-Regular.ttf',
  'packages/common/assets/font/Sarabun-Medium.ttf',
  'packages/common/assets/font/Sarabun-Bold.ttf',
];

/// What to do when the app's widgets no longer overflow, or overflow
/// differently: this file runs in CI, so its failures must say.
String _changed(String widget) =>
    'The layout of $widget changed. If its overflow is fixed, remove the '
    'tolerance in e2e/support/selling_faults.dart (and its counter '
    'assertion in e2e/selling_test.dart) and unskip the FINDING test '
    '"the quantity and payment dialogs fit their text". If only the widget '
    'tree changed, update the chain matched in selling_faults.dart.';

Widget _payment() =>
    PaymentScreen(amount: 75, onCompleted: (_, __) {}, onError: () {});

/// Lays [child] out in [box] and returns every error reported meanwhile.
Future<List<FlutterErrorDetails>> _overflowsOf(
    WidgetTester tester, Widget child, Size box) async {
  final reported = <FlutterErrorDetails>[];
  final testHandler = FlutterError.onError;
  FlutterError.onError = reported.add;
  try {
    await tester.pumpWidget(_inApp(child, box));
  } finally {
    FlutterError.onError = testHandler;
  }
  return reported;
}

Widget _inApp(Widget child, Size box) => MaterialApp(
      theme: CustomTheme.mainTheme,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(size: box, child: child),
        ),
      ),
    );

/// Runs [wrapper] around pumping [child] in [box]; returns what reached the
/// handler that was in place.
Future<List<FlutterErrorDetails>> _passedOn(
  WidgetTester tester,
  Future<void> Function(Future<void> Function() body) wrapper,
  List<(Widget, Size)> layouts,
) async {
  final reached = <FlutterErrorDetails>[];
  final testHandler = FlutterError.onError;
  FlutterError.onError = reached.add;
  try {
    await wrapper(() async {
      for (final (child, box) in layouts) {
        await tester.pumpWidget(_inApp(child, box));
      }
    });
  } finally {
    FlutterError.onError = testHandler;
  }
  return reached;
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Sarabun');
    for (final font in _fonts) {
      loader.addFont(rootBundle.load(font));
    }
    await loader.load();
  });

  group('isPaymentDisplayOverflow', () {
    testWidgets('matches the amount display overflowing in the dialog',
        (tester) async {
      // Act
      final reported = await _overflowsOf(tester, _payment(), _paymentBox);

      // Assert
      expect(reported, hasLength(1), reason: _changed('PaymentScreen'));
      expect(isPaymentDisplayOverflow(reported.single), isTrue,
          reason: _changed('PaymentScreen'));
    });

    testWidgets('does not match another overflow inside the payment screen',
        (tester) async {
      // Act
      final reported =
          await _overflowsOf(tester, _payment(), _crampedPaymentBox);
      final others =
          reported.where((d) => !isPaymentDisplayOverflow(d)).toList();

      // Assert: there, the screen's outer Column (payment_screen.dart:38)
      expect(others, isNotEmpty,
          reason: 'a cramped payment screen overflows elsewhere');
      for (final details in others) {
        expect(details.toString(), contains('A RenderFlex overflowed'));
      }
    });
  });

  group('onPaymentDialog', () {
    testWidgets('swallows and counts the display overflow only',
        (tester) async {
      // Arrange
      final before = paymentDisplayOverflowsSwallowed;

      // Act
      final reached = await _passedOn(tester, onPaymentDialog, [
        (_payment(), _paymentBox),
        (_payment(), _crampedPaymentBox),
      ]);

      // Assert
      expect(reached, isNotEmpty, reason: 'the other overflows are passed on');
      expect(reached.where(isPaymentDisplayOverflow), isEmpty);
      expect(paymentDisplayOverflowsSwallowed, before + 1);
    });

    test('restores the handler in place when the body throws', () async {
      // Arrange
      final inPlace = FlutterError.onError;

      // Act
      await expectLater(
          onPaymentDialog(() async => throw StateError('step failed')),
          throwsStateError);

      // Assert
      expect(FlutterError.onError, same(inPlace));
    });
  });
}
