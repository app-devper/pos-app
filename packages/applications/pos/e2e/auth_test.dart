// Sign-in, sign-out and the server a run talks to, driven through the real
// app against a real UM. Run with tools/e2e/run.sh <local|hosted> auth_test.dart.
//
// The plain admin sign-in comes before the deliberate wrong password: on the
// hosted target, if the owner's own credentials are refused, the harness
// stops the whole run there (see signIn in support/app.dart) instead of
// letting later sign-ins repeat the failure.

// Package imports:
import 'package:common/config/app_config.dart';
import 'package:common/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'support/app.dart';
import 'support/env.dart';
import 'support/pump.dart';
import 'support/robots/shell_robot.dart';

const _hostedApiUrl = 'https://api.devper.app';
const _localApiUrl = 'http://127.0.0.1:8585';

/// What the sign-in alert says for a wrong username or password: um-api's
/// code (errs.ErrWrongCredentials, HTTP 401) after the app's own words. Only
/// a server that checked the password sends it; with no server the alert
/// carries NETWORK_ERROR instead.
const _wrongCredentialsAlert = 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง [UM-401-004]';

void main() {
  initE2E();

  testWidgets('the app is pointed at the server this run names',
      (tester) async {
    // Arrange
    await launchApp(tester);
    final expected =
        E2EEnv.config == 'e2e-local' ? _localApiUrl : _hostedApiUrl;

    // Act
    final apiUrl = getIt()<AppConfig>().apiUrl;

    // Assert
    expect(apiUrl, expected);
  }, timeout: e2eTestTimeout);

  testWidgets(
      'signing in opens the selling screen, signing out returns to sign-in',
      (tester) async {
    // Arrange
    await launchApp(tester);

    // Act
    await signIn(tester);

    // Assert
    expect(ShellRobot(tester).tab('ขายสินค้า'), findsOneWidget);
    expect(find.text('ตะกร้าสินค้า #1').hitTestable(), findsOneWidget);

    // Act
    await signOut(tester);

    // Assert
    expect(find.text('ยินดีต้อนรับ').hitTestable(), findsOneWidget);
    expect(find.text('ตะกร้าสินค้า #1'), findsNothing);
  }, timeout: e2eTestTimeout);

  testWidgets('a wrong password is refused and the user stays on sign-in',
      (tester) async {
    // Arrange
    await launchApp(tester);

    // Act: paced and rate-limit-handled like every sign-in
    final refusal = await signInAttempt(
      tester,
      E2EEnv.username(E2ERole.admin),
      'x-not-the-password',
    );

    // Assert
    expect(refusal, contains(_wrongCredentialsAlert),
        reason: 'the alert should say the username or password is wrong');
    // The alert's barrier fades out after it is dismissed.
    await pumpUntilFound(tester, find.byKey(const Key('login')).hitTestable());
    expect(find.text('ตะกร้าสินค้า #1'), findsNothing);
  }, timeout: e2eTestTimeout);

  testWidgets('each role can sign in', (tester) async {
    for (final role in [E2ERole.manager, E2ERole.user]) {
      // Arrange
      await launchApp(tester);

      // Act
      await signIn(tester, role: role);

      // Assert
      expect(find.text('ตะกร้าสินค้า #1').hitTestable(), findsOneWidget,
          reason: '$role should reach the selling screen');
      await signOut(tester);
    }
  }, timeout: e2eTestTimeout);
}
