import 'dart:ui' show Tristate;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const wide = Size(1280, 800);
const phone = Size(390, 844);

const items = [
  AppShellItem(
      id: 'home',
      label: 'ขายสินค้า',
      shortLabel: 'ขาย',
      icon: Icons.shopping_cart_outlined),
  AppShellItem(
      id: 'order',
      label: 'รายการขาย',
      shortLabel: 'บิล',
      icon: Icons.receipt_long_outlined),
  AppShellItem(id: 'product', label: 'สินค้า', icon: Icons.inventory_2_outlined),
];

Finder tab(String label) =>
    find.byWidgetPredicate((w) => w is AppShellTab && w.label == label);

Future<void> pumpShell(
  WidgetTester tester,
  Size size, {
  String selectedId = 'home',
  ValueChanged<String>? onSelect,
  List<AppShellAction> accountMenu = const [],
  AppShellNavigation navigation = AppShellNavigation.tabs,
  bool showDrawer = true,
  VoidCallback? onBack,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: CustomTheme.mainTheme,
    home: AppShell(
      brand: 'Devper POS',
      title: '',
      showTopBar: false,
      navigation: navigation,
      items: items,
      selectedId: selectedId,
      onSelect: onSelect ?? (_) {},
      accountMenu: accountMenu,
      showDrawer: showDrawer,
      onBack: onBack,
      child: const Center(child: Text('เนื้อหา')),
    ),
  ));
}

void main() {
  testWidgets('wide: the entries are tabs in one row at the top, no sidebar',
      (tester) async {
    await pumpShell(tester, wide);

    final tops = [for (final i in items) tester.getTopLeft(tab(i.label)).dy];
    expect(tops.toSet(), hasLength(1));
    expect(tops.first, lessThan(60));
    expect(tester.getTopLeft(find.text('เนื้อหา')).dy, greaterThan(tops.first));
    expect(find.text('Devper POS'), findsOneWidget);
    expect(find.byType(AppSidebarAction), findsNothing);
    expect(find.byTooltip('เมนู'), findsNothing);
    expect(find.text('ขายสินค้า'), findsOneWidget);
  });

  testWidgets('wide: the chosen tab says so, and a tap reports the other id',
      (tester) async {
    final chosen = <String>[];
    await pumpShell(tester, wide, onSelect: chosen.add);

    final selected = tester.getSemantics(tab('ขายสินค้า'));
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    expect(selected.flagsCollection.isButton, isTrue);
    expect(tester.getSemantics(tab('สินค้า')).flagsCollection.isSelected,
        Tristate.isFalse);

    await tester.tap(tab('รายการขาย'));
    expect(chosen, ['order']);
  });

  testWidgets('phone: a bottom bar with short labels, each 48 px or taller',
      (tester) async {
    final chosen = <String>[];
    await pumpShell(tester, phone, onSelect: chosen.add);

    final content = tester.getRect(find.text('เนื้อหา'));
    for (final item in items) {
      final rect = tester.getRect(tab(item.label));
      expect(rect.top, greaterThan(content.bottom));
      expect(rect.height, greaterThanOrEqualTo(48));
    }
    expect(find.text('ขาย'), findsOneWidget);
    expect(find.text('บิล'), findsOneWidget);
    // An entry without a short label shows its label.
    expect(find.text('สินค้า'), findsOneWidget);
    expect(find.text('ขายสินค้า'), findsNothing);
    expect(find.byTooltip('เมนู'), findsNothing);
    // A screen reader still hears the full name.
    expect(tester.getSemantics(tab('ขายสินค้า')).label, 'ขายสินค้า');

    await tester.tap(tab('รายการขาย'));
    expect(chosen, ['order']);
  });

  for (final size in [wide, phone]) {
    testWidgets('the account button opens its actions ($size)', (tester) async {
      final done = <String>[];
      await pumpShell(tester, size, accountMenu: [
        AppShellAction(
            label: 'ข้อมูลผู้ใช้งาน',
            icon: Icons.account_circle_outlined,
            onTap: () => done.add('info')),
        AppShellAction(
            label: 'ออกจากระบบ',
            icon: Icons.logout,
            destructive: true,
            onTap: () => done.add('logout')),
      ]);

      expect(find.text('ออกจากระบบ'), findsNothing);
      await tester.tap(find.byTooltip('บัญชี'));
      await tester.pumpAndSettle();
      expect(find.text('ข้อมูลผู้ใช้งาน'), findsOneWidget);
      expect(tester.widget<Text>(find.text('ออกจากระบบ')).style?.color,
          CustomColor.error);

      await tester.tap(find.text('ออกจากระบบ'));
      await tester.pumpAndSettle();
      expect(done, ['logout']);
    });
  }

  testWidgets('no account button without account actions', (tester) async {
    await pumpShell(tester, wide);
    expect(find.byTooltip('บัญชี'), findsNothing);
  });

  testWidgets('a page pushed over the host: a phone shows it alone, '
      'a wide screen keeps the tabs', (tester) async {
    await pumpShell(tester, phone, showDrawer: false);
    expect(find.byType(AppShellTab), findsNothing);
    expect(find.text('เนื้อหา'), findsOneWidget);

    await pumpShell(tester, wide, showDrawer: false);
    expect(find.byType(AppShellTab), findsNWidgets(items.length));
  });

  testWidgets('system Back goes to onBack when the shell has one',
      (tester) async {
    var backs = 0;
    await pumpShell(tester, phone, onBack: () => backs++);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(backs, 1);
    expect(find.text('เนื้อหา'), findsOneWidget);
  });

  testWidgets('the default navigation is still the sidebar', (tester) async {
    await pumpShell(tester, wide, navigation: AppShellNavigation.sidebar);

    expect(find.byType(AppSidebarAction), findsWidgets);
    expect(find.byType(AppShellTab), findsNothing);
  });

  testWidgets('the tab bar keeps clear of the status bar and the home bar',
      (tester) async {
    tester.view.padding =
        const FakeViewPadding(top: 40, bottom: 30);
    addTearDown(tester.view.resetPadding);
    await pumpShell(tester, phone);

    final bar = tester.getRect(tab('ขายสินค้า'));
    expect(bar.bottom, lessThanOrEqualTo(844 - 30));
    expect(tester.getRect(find.text('เนื้อหา')).top, greaterThanOrEqualTo(40));
  });
}
