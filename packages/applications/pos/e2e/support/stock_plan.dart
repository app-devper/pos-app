// The values a stock-in run types and reads back, and the chain that stops a
// file of dependent tests at the first broken step. Pure, so it is
// unit-tested.

// Package imports:
import 'package:flutter_test/flutter_test.dart';

/// The one supplier every run reuses: a supplier added through the app has
/// no delete the app can reach, so runs must not add one each.
const keptSupplierName = 'E2E supplier';

/// pos-api's receipt statuses as the app reads them.
const importedReceiveStatus = 'IMPORTED';
const cancelledReceiveStatus = 'CANCELLED';

final _onHand = RegExp(r'^คงเหลือ (-?\d+) ');

/// The lot number a run receives its stock under.
String runLot(String runId) => 'L$runId';

/// [day] one year later as the receipt item dialog takes it: YYYY-MM-DD.
String expiryOneYearAfter(DateTime day) {
  final next = DateTime(day.year + 1, day.month, day.day);
  return '${next.year.toString().padLeft(4, '0')}-'
      '${_twoDigits(next.month)}-${_twoDigits(next.day)}';
}

/// A YYYY-MM-DD date as the product's stock tab shows it: d/M/yy.
String shortDate(String yyyyMmDd) {
  final date = DateTime.parse(yyyyMmDd);
  return '${date.day}/${date.month}/${_twoDigits(date.year % 100)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// The quantity in the product list's subtitle while it is sorted by stock
/// (`คงเหลือ <q> <unit>`); null for the unsorted subtitle (the unit only).
int? onHandIn(String subtitle) {
  final match = _onHand.firstMatch(subtitle);
  return match == null ? null : int.parse(match.group(1)!);
}

/// Tests that build on each other: once a step fails, every later step
/// fails at once naming it, instead of timing out on what is missing.
class StepChain {
  String? _broken;

  Future<void> run(String step, Future<void> Function() body) async {
    final broken = _broken;
    if (broken != null) {
      fail('Not run: the earlier step "$broken" failed');
    }
    try {
      await body();
    } on Object {
      _broken = step;
      rethrow;
    }
  }
}
