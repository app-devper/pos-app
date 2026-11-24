// Undoes what a test created, even when the test fails, and reports once at
// the end of the file whatever could not be undone.
//
// Usage, right after a test creates something:
//   Cleanup.add(RunData.name('product'), () => deleteIt(...));
//
// That one call also schedules the undo for the end of the current test, so
// it cannot be forgotten. Undos run in a tear-down, after flutter_test has
// unmounted the app, so an undo works through the app's repositories (getIt)
// and HTTP, never its screens; that is why it takes no WidgetTester. The
// session is still signed in at that point.

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

typedef Undo = Future<void> Function();

/// A hung undo must not hang the tear-down.
const _undoTimeout = Duration(seconds: 30);

/// Undos run last-in first-out; one that fails or hangs does not stop the
/// rest.
class UndoStack {
  UndoStack({this.timeout = _undoTimeout});

  final Duration timeout;
  final _entries = <({String label, Undo undo})>[];

  /// Labels added and not yet run.
  List<String> get pending => [for (final e in _entries) e.label];

  void add(String label, Undo undo) => _entries.add((label: label, undo: undo));

  /// Runs every undo, newest first, forgets them, and returns the labels of
  /// those that failed or timed out.
  Future<List<String>> run() async {
    final queued = _entries.reversed.toList();
    _entries.clear();
    final leftovers = <String>[];
    for (final entry in queued) {
      try {
        await entry.undo().timeout(timeout);
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

/// Undos plus the bookkeeping that runs them once per test and reports what
/// is left. [registerTearDown] is `addTearDown` outside unit tests.
class CleanupLedger {
  CleanupLedger({required this.registerTearDown, UndoStack? stack})
      : _stack = stack ?? UndoStack();

  final void Function(Future<void> Function() tearDown) registerTearDown;
  final UndoStack _stack;
  final _failed = <String>[];
  final _kept = <String>{};
  bool _tearDownRegistered = false;

  /// Queues [undo] and, on the first add of a test, schedules the tear-down
  /// that runs the queue when that test ends, passed or failed.
  void add(String label, Undo undo) {
    _stack.add(label, undo);
    if (_tearDownRegistered) return;
    _tearDownRegistered = true;
    registerTearDown(_runQueued);
  }

  /// Records [label] as left on purpose; it is reported as given (say why
  /// in the label, e.g. "(kept for reuse)"), never undone.
  void keep(String label) => _kept.add(label);

  Future<void> _runQueued() async {
    _tearDownRegistered = false;
    _failed.addAll(await _stack.run());
  }

  /// What failed, anything still queued (its tear-down never ran), and what
  /// was kept on purpose.
  String report() => leftoversLine([
        ..._failed,
        ..._stack.pending,
        ..._kept,
      ]);
}

/// The process-wide cleanup the e2e tests use.
class Cleanup {
  Cleanup._();

  static final _ledger = CleanupLedger(registerTearDown: addTearDown);

  static void add(String label, Undo undo) => _ledger.add(label, undo);

  /// Reports [label], as given, as left behind on purpose; the label says
  /// why, e.g. `'supplier "X" (kept for reuse)'`.
  static void keep(String label) => _ledger.keep(label);

  /// Called by initE2E(): prints the report after the file's last test.
  static void reportLeftoversAtEnd() {
    tearDownAll(() => debugPrint(_ledger.report()));
  }
}
