// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../e2e/support/sign_in_pacing.dart';

void main() {
  final t0 = DateTime(2026, 11, 25, 12);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  group('waitBeforeSignIn', () {
    test('no wait while fewer than 3 sign-ins fall in the last 60 s', () {
      expect(waitBeforeSignIn([at(0), at(10)], at(20)), Duration.zero);
    });

    test('the 4th within 60 s waits until the oldest of the last 3 is 60 s old',
        () {
      // Act
      final wait = waitBeforeSignIn([at(0), at(10), at(20)], at(30));

      // Assert: at(0) + 60 s + the safety margin, from at(30)
      expect(wait, const Duration(seconds: 30) + signInPacingMargin);
    });

    test('sign-ins older than the window do not count', () {
      expect(waitBeforeSignIn([at(0), at(10), at(20)], at(81)), Duration.zero);
    });

    test('order of the recorded times does not matter', () {
      expect(waitBeforeSignIn([at(20), at(0), at(10)], at(30)),
          const Duration(seconds: 30) + signInPacingMargin);
    });

    test('only the last 3 matter when more were recorded', () {
      // at(50), at(55), at(58) are the last 3: wait until at(50) + 60
      final wait =
          waitBeforeSignIn([at(0), at(5), at(50), at(55), at(58)], at(60));
      expect(wait, const Duration(seconds: 50) + signInPacingMargin);
    });
  });

  group('parseSignInLog', () {
    test('reads one epoch-millisecond time per line and skips junk', () {
      final times = parseSignInLog('${at(0).millisecondsSinceEpoch}\n'
          'junk\n\n${at(5).millisecondsSinceEpoch}\n');
      expect(times, [at(0), at(5)]);
    });
  });
}
