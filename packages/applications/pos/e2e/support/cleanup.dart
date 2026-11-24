// Undoes what a test created, even when the test fails, and reports once at
// the end of the file whatever could not be undone.
//
// Usage, inside the test that creates data:
//   Cleanup.undoAfterThisTest(tester);
//   ... create something ...
//   Cleanup.add(RunData.name('product'), (tester) => deleteIt(...));
//
// Undos run in a tear-down, after flutter_test has unmounted the app, so an
// undo works through the app's repositories (getIt) and HTTP, not its
// screens. The session is still signed in at that point.

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

typedef Undo<T> = Future<void> Function(T context);

/// Undos run last-in first-out; one that fails does not stop the rest.
class UndoStack<T> {
  final _entries = <({String label, Undo<T> undo})>[];

  void add(String label, Undo<T> undo) =>
      _entries.add((label: label, undo: undo));

  /// Runs every undo, newest first, forgets them, and returns the labels of
  /// those that failed.
  Future<List<String>> run(T context) async {
    final pending = _entries.reversed.toList();
    _entries.clear();
    final leftovers = <String>[];
    for (final entry in pending) {
      try {
        await entry.undo(context);
      } on Object catch (error) {
        // Keep going: one stuck record must not leave the rest behind.
        debugPrint('E2E cleanup of "${entry.label}" failed: '
            '${error.runtimeType}');
        leftovers.add(entry.label);
      }
    }
    return leftovers;
  }
}

/// The line printed at the end of a file.
String leftoversLine(List<String> leftovers) =>
    'E2E leftovers: ${leftovers.isEmpty ? 'none' : leftovers.join(', ')}';

/// The process-wide cleanup the e2e tests use.
class Cleanup {
  Cleanup._();

  static final _stack = UndoStack<WidgetTester>();
  static final _leftovers = <String>[];

  static void add(String label, Undo<WidgetTester> undo) =>
      _stack.add(label, undo);

  static Future<List<String>> run(WidgetTester tester) => _stack.run(tester);

  /// Call at the start of a test that creates data: its undos then run when
  /// that test ends, passed or failed.
  static void undoAfterThisTest(WidgetTester tester) {
    addTearDown(() async => _leftovers.addAll(await run(tester)));
  }

  /// Call once in main(): prints [leftoversLine] after the file's last test.
  static void reportLeftoversAtEnd() {
    tearDownAll(() => debugPrint(leftoversLine(_leftovers)));
  }
}
