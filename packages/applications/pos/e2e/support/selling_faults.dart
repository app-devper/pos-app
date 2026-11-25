// Framework errors the selling screen raises that are reported as findings,
// let through only around the step that raises them, and counted. Same
// mechanism as known_faults.dart (which a later task may merge this into).

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The overflowing Column of PaymentScreen's 'ยอดรับเงินรวม' display
/// (payment_screen.dart:221, inside the Container at :213, the Expanded at
/// :43 and the Flexible at :40).
const paymentDisplayChain = [
  'Column', 'Padding', 'DecoratedBox', 'ConstrainedBox', 'Container', //
  'Expanded', 'Column', 'Flexible', 'Column', 'Padding', 'Container',
  'PaymentScreen',
];

final _swallowed = <String, int>{};

/// How many payment display overflows [onPaymentDialog] has let through.
int get paymentDisplayOverflowsSwallowed => _swallowed['PaymentScreen'] ?? 0;

/// FINDING (Task 7): the payment dialog is a fixed 600 px
/// (dialogs.dart:30-37); beside the keypad column (250 + 16 + 64 px) the
/// 'ยอดรับเงินรวม' display gets 77 of its 100 px, so its Column overflows by
/// 18 px (payment_screen.dart:221).
bool isPaymentDisplayOverflow(FlutterErrorDetails details) =>
    _isOverflowOf(details, paymentDisplayChain);

/// Runs [body], which drives the payment dialog, letting its amount
/// display's overflow through and counting it; every other error goes to the
/// handler in place when [body] starts, which is put back when it ends.
Future<T> onPaymentDialog<T>(Future<T> Function() body) => _tolerating(
    'PaymentScreen',
    isPaymentDisplayOverflow,
    'the payment amount display overflows '
        '(payment_screen.dart:221)',
    body);

Future<T> _tolerating<T>(
  String widget,
  bool Function(FlutterErrorDetails) isKnown,
  String finding,
  Future<T> Function() body,
) async {
  final inPlace = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!isKnown(details)) {
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

/// A vertical RenderFlex overflow whose creator chain starts with exactly
/// [chain]: that one Column, not any other flex of the same screen.
bool _isOverflowOf(FlutterErrorDetails details, List<String> chain) {
  if (!details.toString().contains('A RenderFlex overflowed')) return false;
  for (final node
      in details.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
    final flex = node is DiagnosticableNode ? node.value : null;
    if (flex is! RenderFlex || flex.direction != Axis.vertical) continue;
    final creator = flex.debugCreator;
    if (creator is! DebugCreator) continue;
    return listEquals(creatorChain(creator.element, chain.length), chain);
  }
  return false;
}

/// The widget types from [element] up, [depth] of them, as the overflow
/// report's `creator:` line names them.
/// (The chain ends `← ⋯` when the tree goes on above; that is cut off.)
List<String> creatorChain(Element element, int depth) =>
    element.debugGetCreatorChain(depth).split(' ← ').take(depth).toList();
