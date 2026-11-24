// Framework errors the app raises that are already reported as findings,
// let through only around the screen that raises them, and counted, so a
// test can say when the app no longer raises them.
//
// How flutter_test sees them (3.38.7): before each test body the binding
// installs its own FlutterError.onError (binding.dart:877-903), which keeps
// the first error for tester.takeException() and fails the test at its
// end. A layout overflow reaches that handler through
// FlutterError.reportError (debug_overflow_indicator.dart:259), once per
// RenderFlex, when the frame is painted during a pump. So the tolerance
// wraps FlutterError.onError, taking whatever handler is in place when it
// starts and putting it back when it ends.

// Flutter imports:
import 'package:flutter/foundation.dart';

int _swallowed = 0;

/// How many supplier picker overflows [onReceiptPage] has let through in
/// this file so far.
int get supplierPickerOverflowsSwallowed => _swallowed;

/// FINDING (Task 7): the receipt page squeezes its supplier picker into a
/// 50 px box (receive_manage_page.dart:223-227), too low for a labelled
/// DropdownButtonFormField, so once a supplier exists the selected name is
/// clipped and Flutter reports a RenderFlex overflow.
bool isSupplierPickerOverflow(FlutterErrorDetails details) {
  final report = details.toString();
  return report.contains('A RenderFlex overflowed') &&
      report.contains('DropdownButtonFormField<Supplier>');
}

/// Runs [body], which drives the receipt page, letting the supplier
/// picker's overflow through and counting it; every other error goes to the
/// handler in place when [body] starts, which is put back when it ends.
/// Call it after the app is launched, around receipt-page steps only.
Future<T> onReceiptPage<T>(Future<T> Function() body) async {
  final inPlace = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!isSupplierPickerOverflow(details)) {
      inPlace?.call(details);
      return;
    }
    _swallowed++;
    if (_swallowed == 1) {
      debugPrint('E2E known finding shown: the supplier picker overflows '
          '(receive_manage_page.dart:225)');
    }
  };
  try {
    return await body();
  } finally {
    FlutterError.onError = inPlace;
  }
}
