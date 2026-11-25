// Bounded waits. The app has spinners that never settle, so the suite never
// calls pumpAndSettle; it pumps until a finder matches (or stops matching).

// Package imports:
import 'package:flutter_test/flutter_test.dart';

const _step = Duration(milliseconds: 100);
const _defaultTimeout = Duration(seconds: 20);

/// Pumps until [finder] matches at least one widget; fails with the finder's
/// description after [timeout].
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = _defaultTimeout,
}) =>
    pumpUntil(
      tester,
      () => finder.evaluate().isNotEmpty,
      finder.describeMatch(Plurality.many),
      timeout: timeout,
    );

/// Pumps until [finder] matches nothing; fails with the finder's description
/// after [timeout].
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = _defaultTimeout,
}) =>
    pumpUntil(
      tester,
      () => finder.evaluate().isEmpty,
      'no ${finder.describeMatch(Plurality.many)}',
      timeout: timeout,
    );

/// Pumps until [done] holds; fails naming [awaited] after [timeout].
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done,
  String awaited, {
  Duration timeout = _defaultTimeout,
}) async {
  final clock = Stopwatch()..start();
  while (!done()) {
    if (clock.elapsed > timeout) {
      fail('Timed out after $timeout waiting for $awaited');
    }
    await tester.pump(_step);
  }
}
