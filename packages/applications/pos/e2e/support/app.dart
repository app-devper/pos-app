// Starts the real POS app (real DI, repositories and HTTP) inside
// `flutter test` and drives sign-in and sign-out through its screens.

// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:common/config/app_config.dart';
import 'package:common/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:um/container.dart' as um;
import 'package:um/data/datasource/local/token_storage.dart';
import 'package:um/data/datasource/session/app_session.dart';
import 'package:um/data/datasource/session/keep_alive_scheduler.dart';

// Project imports:
import 'package:pos/container.dart' as pos;
import 'package:pos/presentation/app.dart';
import 'cleanup.dart';
import 'env.dart';
import 'pump.dart';
import 'sign_in_pacing.dart';

/// Every e2e test's time bound. LiveTestWidgetsFlutterBinding sets none, so
/// a test stuck on a hung request would otherwise wait for ever. Long
/// enough for the hosted target's sign-in pacing and one rate-limit wait.
const e2eTestTimeout = Timeout(Duration(minutes: 5));

/// 1400 wide keeps the sidebar expanded (labels shown) and the grid inline.
const _surfaceSize = Size(1400, 900);

/// The fonts pubspec.yaml declares. Without them flutter_test draws every
/// glyph as a square one em wide, and Thai labels overflow rows that fit on
/// a real screen.
const _fonts = {
  'Sarabun': [
    'packages/common/assets/font/Sarabun-Regular.ttf',
    'packages/common/assets/font/Sarabun-Medium.ttf',
    'packages/common/assets/font/Sarabun-Bold.ttf',
  ],
  'Roboto': [
    'packages/common/assets/font/roboto_regular.ttf',
    'packages/common/assets/font/roboto_bold.ttf',
  ],
};
const _signInTimeout = Duration(seconds: 30);

/// um-api allows 5 `/auth/login` calls a minute per address and refuses the
/// rest with HTTP 429 `UM-429-001`; the app shows that code in its alert.
const _rateLimitCode = 'UM-429-001';
const _rateLimitWindow = Duration(seconds: 65);

// Both '/' and '/um-splash' build a splash at start, so a screen can be in
// the tree twice; finders go through hitTestable() to take the one on top.
final _signInButton = find.byKey(const Key('login')).hitTestable();
final _sellingScreen = find.text('ตะกร้าสินค้า #1').hitTestable();
final _errorAlert = find.text('พบข้อผิดพลาด').hitTestable();

bool _started = false;

/// Who the app's stored session belongs to; null when there is none.
E2ERole? _sessionRole;

/// `/auth/login` calls this file made, printed at its end.
int _signInCalls = 0;

/// Set once the hosted target refused the suite's own credentials.
bool _stopped = false;

/// um-api's code for a wrong username or password (errs.ErrWrongCredentials).
const _wrongCredentialsCode = '[UM-401-004]';

/// Call first in every e2e file's main().
void initE2E() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test blocks real HTTP by default; the suite talks to a server.
  HttpOverrides.global = null;
  // The analyzer counts only test/ and integration_test/ as test code; e2e/
  // sits apart so that `flutter test` never picks it up.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  E2EEnv.require();
  setUpAll(_loadAppFonts);
  Cleanup.reportLeftoversAtEnd();
  tearDownAll(() => debugPrint('E2E: sign-ins this file: $_signInCalls'));
}

Future<void> _loadAppFonts() async {
  for (final MapEntry(key: family, value: assets) in _fonts.entries) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

/// Runs the app's startup once per file (get_it registrations cannot run
/// twice) and, on every call, pumps the app. flutter_test unmounts the tree
/// after each test, so every test calls this first.
///
/// By default the app starts signed out and this waits for the sign-in
/// screen. With [keepSession], a session an earlier test of this file left
/// is kept: the app's splash restores it (keep-alive, no sign-in call) and
/// this waits for the selling screen; follow with [continueSignedIn]. um-api
/// allows 5 sign-ins a minute, which a hosted run cannot reset.
///
/// The app's own `um.setupLogging()` is left out on purpose: its HTTP
/// logging interceptor prints request and response bodies and every header,
/// which would put passwords and tokens in the test log.
Future<void> launchApp(WidgetTester tester, {bool keepSession = false}) async {
  await _useWideSurface(tester);
  if (!_started) {
    final config = await AppConfig.forEnvironment(E2EEnv.config);
    await um.initCore(config);
    await um.initUm();
    await pos.initPos();
    _started = true;
  }
  final restoring = keepSession && _sessionRole != null;
  if (!restoring) await _forgetSession();
  await tester.pumpWidget(const DevperPos());
  _expectWideLayout(tester);
  if (!restoring) {
    await pumpUntilFound(tester, _signInButton);
    return;
  }
  await pumpUntil(
    tester,
    () =>
        _sellingScreen.evaluate().isNotEmpty ||
        _signInButton.evaluate().isNotEmpty,
    'the restored session or the sign-in screen',
    timeout: _signInTimeout,
  );
  // The server no longer accepts the session: sign in again.
  if (_sellingScreen.evaluate().isEmpty) _sessionRole = null;
}

/// Signs in as [role] unless the app is already signed in as [role]; signs
/// out first when it is signed in as someone else. Use after
/// `launchApp(tester, keepSession: true)`.
Future<void> continueSignedIn(
  WidgetTester tester, {
  E2ERole role = E2ERole.admin,
}) async {
  final signedIn = _sessionRole != null && _sellingScreen.evaluate().isNotEmpty;
  if (signedIn && _sessionRole == role) return;
  if (signedIn) await signOut(tester);
  await signIn(tester, role: role);
}

/// LiveTestWidgetsFlutterBinding lays the app out at its surface size
/// (800x600 unless set) and ignores view.physicalSize, which reaches only
/// MediaQuery; both are set so that layout and MediaQuery agree. Set once
/// per test: a test that launches the app again registers no second reset.
Future<void> _useWideSurface(WidgetTester tester) async {
  if (tester.view.physicalSize == _surfaceSize) return;
  tester.view.physicalSize = _surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Fails at once if the app is not laid out, or not told, at 1400x900.
void _expectWideLayout(WidgetTester tester) {
  final app = find.byType(MaterialApp);
  expect(tester.getSize(app), _surfaceSize, reason: 'laid-out app size');
  expect(MediaQuery.sizeOf(tester.element(app)), _surfaceSize,
      reason: 'MediaQuery size');
}

/// Leaves no session behind from an earlier test that stopped half-way, the
/// way the app's own 401 handling does, so the splash goes to sign-in.
Future<void> _forgetSession() async {
  _sessionRole = null;
  getIt()<KeepAliveScheduler>().stop();
  await getIt()<TokenStorage>().clear();
  getIt()<AppSession>().clear();
}

/// Types [username] and [password] into the sign-in form and submits it;
/// each call is one `/auth/login` call and counts as a sign-in. On the
/// hosted target it first waits so that the suite makes at most
/// [signInPacingMax] in any [signInPacingWindow] (see sign_in_pacing.dart).
Future<void> submitCredentials(
  WidgetTester tester,
  String username,
  String password,
) async {
  if (_stopped) {
    fail('E2E: stopped — the target refused the suite\'s credentials; '
        'check .env.e2e');
  }
  await _pace(tester);
  _signInCalls++;
  await tester.enterText(_field('ชื่อผู้ใช้'), username);
  await tester.enterText(_field('รหัสผ่าน'), password);
  await tester.tap(_signInButton);
  await tester.pump();
}

/// Waits out the pacing, if any, and records this sign-in's time.
Future<void> _pace(WidgetTester tester) async {
  final path = E2EEnv.signInLog;
  if (path.isEmpty) return;
  final log = File(path);
  final earlier =
      log.existsSync() ? parseSignInLog(log.readAsStringSync()) : <DateTime>[];
  final wait = waitBeforeSignIn(earlier, DateTime.now());
  if (wait > Duration.zero) {
    debugPrint('E2E: pacing sign-ins (at most $signInPacingMax a minute on '
        'the hosted target): waiting ${wait.inSeconds}s');
    await _wait(tester, wait);
  }
  log.writeAsStringSync('${DateTime.now().millisecondsSinceEpoch}\n',
      mode: FileMode.append);
}

Finder _field(String label) =>
    find.widgetWithText(TextField, label).hitTestable();

/// Signs in as [role] and waits for the selling screen; fails with the
/// alert the app shows if the server refuses (see [signInAttempt]).
Future<void> signIn(
  WidgetTester tester, {
  E2ERole role = E2ERole.admin,
}) async {
  final refusal =
      await signInAttempt(tester, E2EEnv.username(role), E2EEnv.password(role));
  if (refusal != null) {
    if (refusal.contains(_wrongCredentialsCode)) _stopRun();
    fail('Signing in as ${role.name} was refused: $refusal');
  }
  _sessionRole = role;
}

/// One sign-in with [username] and [password]: returns null on reaching the
/// selling screen, or the refusal the alert showed (the alert is then
/// dismissed). If um-api's rate limit refuses it, waits the window out and
/// tries once more; every attempt is paced (see [submitCredentials]).
Future<String?> signInAttempt(
  WidgetTester tester,
  String username,
  String password,
) async {
  var refusal = await _trySignIn(tester, username, password);
  if (refusal != null && refusal.contains(_rateLimitCode)) {
    debugPrint('E2E: sign-in rate limit reached, waiting '
        '${_rateLimitWindow.inSeconds}s');
    await _dismissAlert(tester);
    await _wait(tester, _rateLimitWindow);
    refusal = await _trySignIn(tester, username, password);
  }
  if (refusal != null) await _dismissAlert(tester);
  return refusal;
}

/// Our own credentials were refused: on the hosted target, stop the whole
/// run (run-all.sh checks the stop file after each file) so that no later
/// file repeats a failing sign-in, which could lock the account.
void _stopRun() {
  if (!E2EEnv.isHosted) return;
  _stopped = true;
  if (E2EEnv.stopFile.isNotEmpty) {
    File(E2EEnv.stopFile).writeAsStringSync('wrong credentials\n');
  }
  debugPrint('E2E: the hosted target refused the suite\'s credentials; '
      'stopping the run — check .env.e2e');
}

/// Submits [username]'s credentials; returns null on reaching the selling
/// screen, or the text of the alert the app showed instead.
Future<String?> _trySignIn(
    WidgetTester tester, String username, String password) async {
  await submitCredentials(tester, username, password);
  await pumpUntil(
    tester,
    () =>
        _sellingScreen.evaluate().isNotEmpty ||
        _errorAlert.evaluate().isNotEmpty,
    'the selling screen or an error alert',
    timeout: _signInTimeout,
  );
  return _errorAlert.evaluate().isEmpty ? null : _alertText(tester);
}

Future<void> _dismissAlert(WidgetTester tester) async {
  await tester.tap(find.text('ตกลง').hitTestable());
  await pumpUntilGone(tester, _errorAlert);
}

/// Keeps pumping frames for [duration] of real time.
Future<void> _wait(WidgetTester tester, Duration duration) {
  final clock = Stopwatch()..start();
  return pumpUntil(
    tester,
    () => clock.elapsed >= duration,
    'the end of a ${duration.inSeconds}s wait',
    timeout: duration + const Duration(seconds: 5),
  );
}

String _alertText(WidgetTester tester) => find
    .descendant(of: find.byType(AlertDialog), matching: find.byType(Text))
    .evaluate()
    .map((e) => (e.widget as Text).data ?? '')
    .join(' | ');

/// Signs out from the sidebar and waits for the sign-in screen.
Future<void> signOut(WidgetTester tester) async {
  _sessionRole = null;
  await tester.tap(find.byTooltip('ออกจากระบบ').hitTestable());
  await pumpUntilFound(tester, find.text('ยินดีต้อนรับ').hitTestable());
  // The home route animates out after sign-in shows; wait until it has gone.
  await pumpUntilGone(tester, find.text('ตะกร้าสินค้า #1'));
}
