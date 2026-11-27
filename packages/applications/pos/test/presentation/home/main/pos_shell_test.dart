// The shell's tabs and account menu: who sees which sections, on a wide
// screen and on a phone.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/localizations/localizations_delegate.dart';
import 'package:design_system/theme/theme.dart';
import 'package:design_system/widgets/app_shell_tabs.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/pos_shell.dart';
import '../../../support/app_languages.dart';

const _wide = Size(1280, 800);
const _phone = Size(390, 844);

List<String> _tabLabels(WidgetTester tester) => [
      for (final tab in tester.widgetList<AppShellTab>(find.byType(AppShellTab)))
        tab.label,
    ];

Future<List<String>> _pumpShell(
  WidgetTester tester, {
  required bool isAdmin,
  required Size size,
  VoidCallback? onLogout,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chosen = <String>[];
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    localizationsDelegates: [CommonLocalizationsDelegate(), thaiLanguages],
    home: PosShell(
      isAdmin: isAdmin,
      selectedId: 'home',
      onSelect: chosen.add,
      onLogout: onLogout ?? () {},
      child: const Center(child: Text('เนื้อหา')),
    ),
  ));
  await tester.pump();
  return chosen;
}

void main() {
  for (final size in [_wide, _phone]) {
    testWidgets('an admin has the four sections as tabs at $size',
        (tester) async {
      await _pumpShell(tester, isAdmin: true, size: size);

      expect(_tabLabels(tester), ['ขายสินค้า', 'รายการขาย', 'สินค้า', 'จัดการ']);
    });

    testWidgets('a cashier or manager has selling and bills only at $size',
        (tester) async {
      await _pumpShell(tester, isAdmin: false, size: size);

      expect(_tabLabels(tester), ['ขายสินค้า', 'รายการขาย']);
      expect(find.text('จัดการ'), findsNothing);
    });

    testWidgets('every role can reach user info and sign out at $size',
        (tester) async {
      var loggedOut = 0;
      await _pumpShell(tester,
          isAdmin: false, size: size, onLogout: () => loggedOut++);

      await tester.tap(find.byTooltip(AppShellAccountButton.tooltip));
      await tester.pumpAndSettle();
      expect(find.text('ข้อมูลผู้ใช้งาน'), findsOneWidget);

      await tester.tap(find.text(PosShell.logoutLabel));
      await tester.pumpAndSettle();
      expect(loggedOut, 1);
    });
  }

  testWidgets('a phone shows the short names; a tap reports the section',
      (tester) async {
    final chosen = await _pumpShell(tester, isAdmin: true, size: _phone);

    expect(find.text('ขาย'), findsOneWidget);
    expect(find.text('บิล'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('บิล'));
    expect(chosen, ['order']);
  });

  testWidgets('five entries fit a 360 px phone at a large text size',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpShell(tester, isAdmin: true, size: const Size(360, 640));

    expect(tester.takeException(), isNull);
  });
}
