// Starts the real POS app (real DI, repositories and HTTP) inside
// `flutter test` and drives sign-in and sign-out through its screens.

// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

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
import 'env.dart';
import 'pump.dart';

/// 1400 wide keeps the sidebar expanded (labels shown) and the grid inline.
const _surfaceSize = Size(1400, 900);
const _signInTimeout = Duration(seconds: 30);

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
  tester.view.physicalSize = _surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (!_started) {
    final config = await AppConfig.forEnvironment(E2EEnv.config);
    await um.initCore(config);
    await um.initUm();
    await pos.initPos();
    _started = true;
  }
  await _forgetSession();
  await tester.pumpWidget(const DevperPos());
  await pumpUntilFound(tester, _signInButton);
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

/// Signs in as [role] and waits for the selling screen. If the server
/// refuses, fails with the alert the app shows instead of timing out.
Future<void> signIn(
  WidgetTester tester, {
  E2ERole role = E2ERole.admin,
}) async {
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
  if (_errorAlert.evaluate().isNotEmpty) {
    fail('Signing in as ${role.name} was refused: ${_alertText(tester)}');
  }
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
