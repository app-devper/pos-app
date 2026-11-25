// Framework errors the selling screen raises that are reported as findings,
// let through only around the step that raises them, and counted. Same
// mechanism as known_faults.dart (which a later task may merge this into).

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The widget-tree depth searched for the dialog that raised an overflow.
const _creatorDepth = 40;

final _swallowed = <String, int>{};

/// How many quantity keypad overflows [onQuantityKeypad] has let through.
int get quantityKeypadOverflowsSwallowed => _swallowed['DecimalInput'] ?? 0;

/// How many payment display overflows [onPaymentDialog] has let through.
int get paymentDisplayOverflowsSwallowed => _swallowed['PaymentScreen'] ?? 0;

/// FINDING (Task 7): the cart's quantity dialog is a fixed 430 px
/// (dialogs.dart:96-99); under the TitleBar, the 250 px keypad and the
/// padding, DecimalInput's display gets 51 px for a 20 px title and a 24 px
/// figure, so its Column overflows by 12 px (decimal_input.dart:103).
bool isQuantityKeypadOverflow(FlutterErrorDetails details) =>
    _isOverflowUnder(details, 'DecimalInput');

/// FINDING (Task 7): the payment dialog is a fixed 600 px
/// (dialogs.dart:30-37); beside the keypad column (250 + 16 + 64 px) the
/// 'ยอดรับเงินรวม' display gets 77 of its 100 px, so its Column overflows by
/// 18 px (payment_screen.dart:221).
bool isPaymentDisplayOverflow(FlutterErrorDetails details) =>
    _isOverflowUnder(details, 'PaymentScreen');

/// Runs [body], which opens the cart's quantity dialog, letting the keypad
/// display's overflow through and counting it; every other error goes to the
/// handler in place when [body] starts, which is put back when it ends.
Future<T> onQuantityKeypad<T>(Future<T> Function() body) => _tolerating(
    'DecimalInput',
    'the quantity keypad display overflows '
        '(decimal_input.dart:103)',
    body);

/// As [onQuantityKeypad], for the payment dialog's amount display.
Future<T> onPaymentDialog<T>(Future<T> Function() body) => _tolerating(
    'PaymentScreen',
    'the payment amount display overflows '
        '(payment_screen.dart:221)',
    body);

Future<T> _tolerating<T>(
    String widget, String finding, Future<T> Function() body) async {
  final inPlace = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!_isOverflowUnder(details, widget)) {
      inPlace?.call(details);
      return;
    }
    final count = (_swallowed[widget] ?? 0) + 1;
    _swallowed[widget] = count;
    if (count == 1) debugPrint('E2E known finding shown: $finding');
  };
  try {
    return await body();
  } finally {
    FlutterError.onError = inPlace;
  }
}

/// An overflow whose RenderFlex was built under a [widget]: named in the
/// report, or found in the overflowing render object's creator chain (the
/// report itself names only the Column).
bool _isOverflowUnder(FlutterErrorDetails details, String widget) {
  final report = details.toString();
  if (!report.contains('A RenderFlex overflowed')) return false;
  if (report.contains(widget)) return true;
  for (final node
      in details.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
    final creator = _creatorOf(node);
    if (creator != null &&
        creator.element.debugGetCreatorChain(_creatorDepth).contains(widget)) {
      return true;
    }
  }
  return false;
}

/// The widget behind a report node: the relevant widget's DebugCreator, or
/// the creator of the RenderFlex the report describes.
DebugCreator? _creatorOf(DiagnosticsNode node) {
  final Object? value = node is DiagnosticsProperty
      ? node.value
      : node is DiagnosticableNode
          ? node.value
          : null;
  if (value is DebugCreator) return value;
  final creator = value is RenderObject ? value.debugCreator : null;
  return creator is DebugCreator ? creator : null;
}
