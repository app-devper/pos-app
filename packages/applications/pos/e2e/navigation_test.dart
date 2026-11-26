// Every area of the app opens its screen, and what each role is shown.
// Writes nothing. Run with tools/e2e/run.sh <local|hosted> navigation_test.dart.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'support/app.dart';
import 'support/env.dart';
import 'support/pump.dart';
import 'support/robots/shell_robot.dart';

const _manageTiles = [
  'ร้านค้าของฉัน',
  'จัดการลูกค้า',
  'จัดการผู้ใช้งาน',
  'ใบรับสินค้า / Goods Receipt',
  'นับสต็อก',
];

void main() {
  initE2E();

  testWidgets('every area an admin can open shows its screen', (tester) async {
    // Arrange
    await launchApp(tester, keepSession: true);
    await continueSignedIn(tester);
    final shell = ShellRobot(tester);

    // Act / Assert: the sidebar areas
    await shell.openSelling();
    await shell.expectScreenWithoutError(find.text('ตะกร้าสินค้า #1'));

    await shell.openOrders();
    await shell.expectScreenWithoutError(find.text('สรุปรายการ'));
    expect(shell.choiceChip('All'), findsOneWidget);
    expect(find.text('ต้นทุน').hitTestable(), findsOneWidget);

    await shell.openProducts();
    await shell.expectScreenWithoutError(
        shell.searchField('ค้นหาสิ่งที่คุณต้องการ...'));
    expect(find.text('เพิ่มสินค้า').hitTestable(), findsOneWidget);

    await shell.openManage();
    await shell.expectScreenWithoutError(find.text(_manageTiles.first));
    for (final tile in _manageTiles) {
      expect(find.text(tile).hitTestable(), findsOneWidget, reason: tile);
    }

    // Act / Assert: the จัดการ tiles, each left again the way it is meant to be
    await _shopProfileOpensUntouched(shell);
    await _customersOpenAndReturn(shell);
    await _goodsReceiptsOpenAndReturn(shell);
    await _stockCountsOpenAndReturn(shell);
    await _userInfoOpensAndReturns(shell);
  }, timeout: e2eTestTimeout);

  // Was finding #5: OrderViewModel.checkLogin wrote back the state it read
  // before awaiting the role, wiping the ranges initData set meanwhile, so
  // no one ever got the range dropdown. The non-admin tests below check
  // that they still do not.
  group('bills date range', () {
    testWidgets('an admin can choose the date range of the bills',
        (tester) async {
      // Arrange
      await launchApp(tester, keepSession: true);
      await continueSignedIn(tester);
      final shell = ShellRobot(tester);

      // Act
      await shell.openOrders();
      await shell.expectScreenWithoutError(find.text('สรุปรายการ'));
      await shell.waitForRoleToApply();

      // Assert
      expect(shell.rangeDropdown, findsOneWidget);
    }, timeout: e2eTestTimeout);
  });

  testWidgets(
      'a user sees selling and bills only, '
      'and the bills without the store filter or total cost', (tester) async {
    // Arrange
    await launchApp(tester, keepSession: true);
    await continueSignedIn(tester, role: E2ERole.user);

    // Act / Assert
    await _expectSellingAndBillsWithoutAdminTools(ShellRobot(tester));
  }, timeout: e2eTestTimeout);

  testWidgets('a manager sees what a user sees', (tester) async {
    // Arrange
    await launchApp(tester, keepSession: true);
    await continueSignedIn(tester, role: E2ERole.manager);

    // Act / Assert
    await _expectSellingAndBillsWithoutAdminTools(ShellRobot(tester));
  }, timeout: e2eTestTimeout);
}

/// With no shop profile yet the form is empty and says so
/// (`ยังไม่มีข้อมูลร้านค้า กรอกแล้วกดบันทึก`); it used to show a red
/// "Error: ไม่พบข้อมูลที่ต้องการ [SY-404-002]" (was finding #14). No error is
/// tolerated any more, on an empty or a populated database.
const _noShopProfileHint = 'ยังไม่มีข้อมูลร้านค้า กรอกแล้วกดบันทึก';

/// Opened and read only: the profile may be the shop's real one, so its
/// Update button is checked for and never pressed.
Future<void> _shopProfileOpensUntouched(ShellRobot shell) async {
  await shell.openManageTile('ร้านค้าของฉัน');
  await shell.expectScreenWithoutError(shell.appBarTitle('ร้านของฉัน'));
  expect(find.byKey(const Key('update')).hitTestable(), findsOneWidget);
  // Once loaded, the form holds the profile or, with none yet, says so.
  final hint = find.text(_noShopProfileHint);
  String name() => shell.tester
      .widget<TextField>(find
          .byWidgetPredicate(
              (w) => w is TextField && w.decoration?.labelText == 'Name*')
          .first)
      .controller!
      .text;
  await pumpUntil(shell.tester,
      () => hint.evaluate().isNotEmpty || name().isNotEmpty, 'the profile');
  expect(hint, name().isEmpty ? findsOneWidget : findsNothing);
  await shell.pageBack();
  await pumpUntilFound(shell.tester, find.text('ร้านค้าของฉัน').hitTestable());
}

Future<void> _customersOpenAndReturn(ShellRobot shell) async {
  await shell.openManageTile('จัดการลูกค้า');
  await shell.expectScreenWithoutError(find.text('ข้อมูลลูกค้า'));
  await shell.backFromCustomers();
  await pumpUntilFound(shell.tester, find.text('จัดการลูกค้า').hitTestable());
}

/// The goods-receipt list has no back control; the sidebar leaves it.
Future<void> _goodsReceiptsOpenAndReturn(ShellRobot shell) async {
  await shell.openManageTile('ใบรับสินค้า / Goods Receipt');
  await shell
      .expectScreenWithoutError(shell.searchField('ค้นหาเลขที่ใบรับสินค้า...'));
  await shell.openManage();
}

Future<void> _stockCountsOpenAndReturn(ShellRobot shell) async {
  await shell.openManageTile('นับสต็อก');
  await shell.expectScreenWithoutError(shell.appBarTitle('นับสต็อก'));
  await shell.pageBack();
  await pumpUntilGone(shell.tester, shell.appBarTitle('นับสต็อก'));
}

Future<void> _userInfoOpensAndReturns(ShellRobot shell) async {
  await shell.openUserInfo();
  await shell.expectScreenWithoutError(find.text('ข้อมูลของฉัน'));
  await shell.pageBack();
  await pumpUntilGone(shell.tester, find.text('ข้อมูลของฉัน'));
}

Future<void> _expectSellingAndBillsWithoutAdminTools(ShellRobot shell) async {
  await shell.openOrders();
  await shell.expectScreenWithoutError(find.text('สรุปรายการ'));
  // The role is read after the screen first draws; give it time to arrive
  // so that "not shown" is not just "not shown yet".
  await shell.waitForRoleToApply();

  expect(shell.sidebarItem('ขายสินค้า'), findsOneWidget);
  expect(shell.sidebarItem('รายการขาย'), findsOneWidget);
  expect(shell.sidebarItem('สินค้า'), findsNothing);
  expect(shell.sidebarItem('จัดการ'), findsNothing);
  expect(shell.choiceChip('All'), findsNothing);
  expect(find.text('ต้นทุน'), findsNothing);
  expect(shell.rangeDropdown, findsNothing);
}
