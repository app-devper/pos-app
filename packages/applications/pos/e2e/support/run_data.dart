// Names and barcodes for the data a run creates, so that data is easy to
// find (and clean up) on a shared server and never collides between runs.

// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'env.dart';

/// The run id starts with the time the run began: yyyyMMddHHmmss.
final _runStart = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})');

/// Seconds are counted from here, so they fit in nine digits until 2051.
final _epoch = DateTime.utc(2020);
const _secondsDigits = 9;
const _numberDigits = 3;

/// The 20–29 GS1 prefixes are for in-store use, so a run's barcodes never
/// match a real product's.
const _inStorePrefix = '2';

class RunData {
  RunData._();

  /// How many distinct barcodes one run can ask for.
  static const maxBarcodes = 999;

  /// `E2E-<run id> <what>`, e.g. `E2E-20261124153012-4242 product`.
  static String name(String what) => nameIn(E2EEnv.runId, what);

  /// 13 digits: unique per [n] within this run and different from every
  /// barcode of a run started at least one second earlier or later.
  static String barcode(int n) => barcodeIn(E2EEnv.runId, n);

  /// The prefix every run's names carry: `E2E-`.
  static const namePrefix = 'E2E-';

  /// Matches what [nameIn] produces for a run id of the shape run.sh gives
  /// (`yyyyMMddHHmmss-<pid>`), and nothing else: not the kept `E2E
  /// customer` or `E2E supplier`, nor a real `E2E-…` name. The sweep acts
  /// only on names it matches.
  static final runNamePattern = RegExp('^$namePrefix\\d{14}-\\d+ ');

  @visibleForTesting
  static String nameIn(String runId, String what) => '$namePrefix$runId $what';

  @visibleForTesting
  static String barcodeIn(String runId, int n) {
    if (n < 1 || n > maxBarcodes) {
      throw ArgumentError.value(n, 'n', 'must be 1..$maxBarcodes');
    }
    final seconds = _startOf(runId).difference(_epoch).inSeconds;
    return _inStorePrefix +
        seconds.toString().padLeft(_secondsDigits, '0') +
        n.toString().padLeft(_numberDigits, '0');
  }

  static DateTime _startOf(String runId) {
    final match = _runStart.firstMatch(runId);
    if (match == null) {
      throw ArgumentError.value(
          runId, 'runId', 'must start with yyyyMMddHHmmss');
    }
    final parts = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    return DateTime.utc(
        parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
  }
}
