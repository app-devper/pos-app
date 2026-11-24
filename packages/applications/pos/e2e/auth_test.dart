// Sign-in, sign-out and the server a run talks to, driven through the real
// app against a real UM. Run with tools/e2e/run.sh <local|hosted> auth_test.dart.

// Package imports:
import 'package:common/config/app_config.dart';
import 'package:common/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'support/app.dart';
import 'support/env.dart';
import 'support/pump.dart';

const _hostedApiUrl = 'https://api.devper.app';
const _localApiUrl = 'http://127.0.0.1:8585';

/// um-api's code for a wrong username or password (errs.ErrWrongCredentials,
/// HTTP 401). Only a server that checked the password sends it; with no
/// server the alert carries NETWORK_ERROR instead.
const _wrongCredentialsCode = '[UM-401-004]';

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
  });

  testWidgets('a wrong password is refused and the user stays on sign-in',
      (tester) async {
    // Arrange
    await launchApp(tester);

    // Act
    await submitCredentials(
      tester,
      E2EEnv.username(E2ERole.admin),
      'x-not-the-password',
    );
    await pumpUntilFound(tester, find.text('พบข้อผิดพลาด').hitTestable());
    final refusal = find.textContaining(_wrongCredentialsCode).hitTestable();
    final refusedByServer = refusal.evaluate().length;
    await tester.tap(find.text('ตกลง').hitTestable());
    await pumpUntilGone(tester, find.text('พบข้อผิดพลาด'));

    // Assert
    expect(refusedByServer, 1,
        reason:
            'the alert should carry the server code $_wrongCredentialsCode');
    expect(find.byKey(const Key('login')).hitTestable(), findsOneWidget);
    expect(find.text('ตะกร้าสินค้า #1'), findsNothing);
  });

  testWidgets(
      'signing in opens the selling screen, signing out returns to sign-in',
      (tester) async {
    // Arrange
    await launchApp(tester);

    // Act
    await signIn(tester);

    // Assert
    expect(find.byTooltip('ขายสินค้า').hitTestable(), findsOneWidget);
    expect(find.text('ตะกร้าสินค้า #1').hitTestable(), findsOneWidget);

    // Act
    await signOut(tester);

    // Assert
    expect(find.text('ยินดีต้อนรับ').hitTestable(), findsOneWidget);
    expect(find.text('ตะกร้าสินค้า #1'), findsNothing);
  });

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
  });
}
