// How long to wait before the next `/auth/login` on the hosted target. Pure
// (the clock is a parameter), so it is unit-tested.
//
// um-api allows 5 sign-ins a minute per client address
// (um-api app/featues/api/auth.go:31, middlewares/rate_limit.go:17-21), and
// its own comment says the deployed service may see every request from the
// gateway's address (rate_limit.go:23-25), so that limit may be shared with
// every user behind the gateway. The suite keeps to 3 in any 60 s to leave
// room for them.

/// Sign-ins allowed in any [signInPacingWindow].
const signInPacingMax = 3;
const signInPacingWindow = Duration(seconds: 60);

/// Added to every wait so that clock skew never lands a 4th sign-in inside
/// the window.
const signInPacingMargin = Duration(seconds: 2);

/// Zero while fewer than [max] of [earlier] fall in the [window] before
/// [now]; otherwise the time until the oldest of the last [max] leaves the
/// window, plus [signInPacingMargin].
Duration waitBeforeSignIn(
  Iterable<DateTime> earlier,
  DateTime now, {
  int max = signInPacingMax,
  Duration window = signInPacingWindow,
}) {
  final recent = earlier.where((t) => now.difference(t) < window).toList()
    ..sort();
  if (recent.length < max) return Duration.zero;
  final oldestCounted = recent[recent.length - max];
  return oldestCounted.add(window).difference(now) + signInPacingMargin;
}

/// The sign-in log: one epoch-millisecond time per line; other lines are
/// skipped.
List<DateTime> parseSignInLog(String text) => [
      for (final line in text.split('\n'))
        if (int.tryParse(line.trim()) case final ms?)
          DateTime.fromMillisecondsSinceEpoch(ms),
    ];
