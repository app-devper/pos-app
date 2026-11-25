// Finding a row in a lazily built list the way a user does: from the top,
// scrolling down until it shows or the list ends. A real catalogue or
// customer list is long, and pos-api returns rows unsorted, so the run's
// own row can be anywhere, often last.

// Flutter imports:
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

const _step = Duration(milliseconds: 100);
const _scrollStep = Offset(0, -300);

/// A long list on a slow target still ends well within this.
const _scrollTimeout = Duration(seconds: 90);

/// Scrolls [scrollable] to its top, then down until [target] is
/// hit-testable; returns false once the list has ended without it. Fails
/// naming [what] if the scrolling takes longer than [timeout].
Future<bool> scrollUntilShown(
  WidgetTester tester,
  Finder scrollable,
  Finder target, {
  required String what,
  Duration timeout = _scrollTimeout,
}) async {
  final clock = Stopwatch()..start();
  void checkTime() {
    if (clock.elapsed > timeout) {
      fail('Timed out after $timeout scrolling to $what');
    }
  }

  ScrollPosition position() =>
      tester.state<ScrollableState>(scrollable.first).position;
  while (position().pixels > position().minScrollExtent) {
    checkTime();
    await tester.drag(scrollable.first, -_scrollStep);
    await tester.pump(_step);
  }
  while (target.hitTestable().evaluate().isEmpty) {
    checkTime();
    if (position().pixels >= position().maxScrollExtent) return false;
    await tester.drag(scrollable.first, _scrollStep);
    await tester.pump(_step);
  }
  return true;
}
