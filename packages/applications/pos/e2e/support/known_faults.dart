// Framework errors the app raises that are already reported as findings,
// let through where a test has to pass the screen that raises them. Each
// one is matched narrowly, so any other error still fails the test.

// Flutter imports:
import 'package:flutter/foundation.dart';

/// FINDING (Task 7): the receipt page squeezes its supplier picker into a
/// 50 px box (receive_manage_page.dart:223-227), too low for a labelled
/// DropdownButtonFormField, so once a supplier exists the selected name is
/// clipped and Flutter reports a RenderFlex overflow.
bool isSupplierPickerOverflow(String report) =>
    report.contains('A RenderFlex overflowed') &&
    report.contains('DropdownButtonFormField<Supplier>');

/// Runs [body] with the supplier picker's overflow let through (logged once
/// as a known finding); every other error goes to the handler in place.
Future<T> toleratingSupplierPickerOverflow<T>(Future<T> Function() body) async {
  final previous = FlutterError.onError;
  var logged = false;
  FlutterError.onError = (details) {
    if (!isSupplierPickerOverflow(details.toString())) {
      previous?.call(details);
      return;
    }
    if (!logged) {
      logged = true;
      debugPrint('E2E known finding shown: the supplier picker overflows '
          '(receive_manage_page.dart:225)');
    }
  };
  try {
    return await body();
  } finally {
    FlutterError.onError = previous;
  }
}
