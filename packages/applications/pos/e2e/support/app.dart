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
/// twice) and, on every call, pumps the app signed out and waits for the
/// sign-in screen. flutter_test unmounts the tree after each test, so every
/// test calls this first.
///
/// The app's own `um.setupLogging()` is left out on purpose: its HTTP
/// logging interceptor prints request and response bodies and every header,
/// which would put passwords and tokens in the test log.
Future<void> launchApp(WidgetTester tester) async {
  await _useWideSurface(tester);
  if (!_started) {
    final config = await AppConfig.forEnvironment(E2EEnv.config);
    await um.initCore(config);
    await um.initUm();
    await pos.initPos();
    _started = true;
  }
  await _forgetSession();
  await tester.pumpWidget(const DevperPos());
  _expectWideLayout(tester);
  await pumpUntilFound(tester, _signInButton);
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
  getIt()<KeepAliveScheduler>().stop();
  await getIt()<TokenStorage>().clear();
  getIt()<AppSession>().clear();
}

/// Types [username] and [password] into the sign-in form and submits it.
Future<void> submitCredentials(
  WidgetTester tester,
  String username,
  String password,
) async {
  await tester.enterText(_field('ชื่อผู้ใช้'), username);
  await tester.enterText(_field('รหัสผ่าน'), password);
  await tester.tap(_signInButton);
  await tester.pump();
}

Finder _field(String label) =>
    find.widgetWithText(TextField, label).hitTestable();

/// Signs in as [role] and waits for the selling screen. If um-api's sign-in
/// rate limit refuses it, waits the window out and tries once more; any
/// other refusal fails at once with the alert the app shows.
Future<void> signIn(
  WidgetTester tester, {
  E2ERole role = E2ERole.admin,
}) async {
  var refusal = await _trySignIn(tester, role);
  if (refusal != null && refusal.contains(_rateLimitCode)) {
    debugPrint('E2E: sign-in rate limit reached, waiting '
        '${_rateLimitWindow.inSeconds}s');
    await _dismissAlert(tester);
    await _wait(tester, _rateLimitWindow);
    refusal = await _trySignIn(tester, role);
  }
  if (refusal != null) {
    fail('Signing in as ${role.name} was refused: $refusal');
  }
}

/// Submits [role]'s credentials; returns null on reaching the selling
/// screen, or the text of the alert the app showed instead.
Future<String?> _trySignIn(WidgetTester tester, E2ERole role) async {
  await submitCredentials(
    tester,
    E2EEnv.username(role),
    E2EEnv.password(role),
  );
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
  await tester.tap(find.byTooltip('ออกจากระบบ').hitTestable());
  await pumpUntilFound(tester, find.text('ยินดีต้อนรับ').hitTestable());
  // The home route animates out after sign-in shows; wait until it has gone.
  await pumpUntilGone(tester, find.text('ตะกร้าสินค้า #1'));
}
