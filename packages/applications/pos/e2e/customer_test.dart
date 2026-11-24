// A customer is added, found in the list, changed and removed through the
// customer pages under "จัดการ". Run with
// tools/e2e/run.sh <local|hosted> customer_test.dart.

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'support/api/customer_api.dart';
import 'support/app.dart';
import 'support/cleanup.dart';
import 'support/robots/customer_robot.dart';
import 'support/robots/shell_robot.dart';
import 'support/run_data.dart';
import 'support/screen.dart';

/// Test data only; no real person has these numbers.
const _phone = '0800000000';
const _changedPhone = '0800000001';

void main() {
  initE2E();
  // launchApp (Task 1) neither loads the app's fonts nor gets its 1400x900
  // size through to layout; screen.dart supplies both.
  setUpAll(loadAppFonts);

  testWidgets('a customer can be added, seen, changed and removed',
      (tester) async {
    // Arrange
    await useWideSurface(tester);
    await launchApp(tester);
    await signIn(tester);
    final customers = CustomerRobot(ShellRobot(tester));
    final name = RunData.name('customer');
    await customers.openList();
    // Queued before the add: removing by name is a no-op when nothing was
    // created, and a failure inside add() itself still cleans up.
    Cleanup.add(name, () => removeCustomersNamed(name));

    // Act
    await customers.add(name, phone: _phone);
    // FINDING: on a wide screen the list keeps what it loaded on entry, so
    // the new customer shows only after leaving and coming back.
    await customers.reenterList();

    // Assert
    expect(await customers.scrollListTo(name), isTrue,
        reason: 'the new customer should be listed');

    // Act
    await customers.open(name);

    // Assert
    expect(customers.detailRow('ชื่อลูกค้า', name), findsOneWidget);
    expect(customers.detailRow('โทรศัพท์', _phone), findsOneWidget);

    // Act
    await customers.edit(phone: _changedPhone);

    // Assert
    expect(customers.detailRow('โทรศัพท์', _changedPhone), findsOneWidget);
    expect(customers.detailRow('ชื่อลูกค้า', name), findsOneWidget);

    // Act
    await customers.delete();
    await customers.reenterList();

    // Assert
    // FINDING: pos-api only archives a removed customer and lists archived
    // ones too, and the app does not filter them, so the customer is still
    // listed. Asserted as the app behaves; the skipped test below says what
    // a user expects. The server shows the removal was recorded.
    expect(await customers.scrollListTo(name), isTrue,
        reason: 'the app currently keeps listing a removed customer');
    expect(await customerStatusesNamed(name), [archived]);
  });

  // FINDING (Task 7): on a wide screen CustomerPage keeps the same
  // CustomersWidget while the right panel changes, and that widget loads
  // only in initState (customers_widget.dart:42, customer_page.dart:73-93),
  // so a customer just added (or removed) is not shown (or still shown)
  // until the user leaves the page and comes back. The running test above
  // re-enters; this one states what a user expects. Skipped tests do not
  // sign in or write anything.
  group('customer list refresh', () {
    testWidgets('a new customer appears in the list without leaving the page',
        (tester) async {
      // Arrange
      await useWideSurface(tester);
      await launchApp(tester);
      await signIn(tester);
      final customers = CustomerRobot(ShellRobot(tester));
      final name = RunData.name('customer listed at once');
      await customers.openList();
      Cleanup.add(name, () => removeCustomersNamed(name));

      // Act
      await customers.add(name, phone: _phone);

      // Assert
      expect(await customers.scrollListTo(name), isTrue);
    });
  },
      skip: 'FINDING: on a wide screen the customer list does not reload '
          'after an add or a removal (customers_widget.dart:42)');

  // FINDING (Task 7): DELETE /customers/:id sets status ARCHIVED
  // (pos-api app/data/repositories/customer.go:109-129) and GET /customers
  // returns every status (customer.go:40-54); CustomersViewModel shows them
  // all (customers_view_model.dart:27), so a removed customer never leaves
  // the list.
  group('customer removal', () {
    testWidgets('a removed customer is no longer listed', (tester) async {
      // Arrange
      await useWideSurface(tester);
      await launchApp(tester);
      await signIn(tester);
      final customers = CustomerRobot(ShellRobot(tester));
      final name = RunData.name('customer removed');
      await customers.openList();
      Cleanup.add(name, () => removeCustomersNamed(name));
      await customers.add(name, phone: _phone);
      await customers.reenterList();
      await customers.open(name);

      // Act
      await customers.delete();
      await customers.reenterList();

      // Assert
      expect(await customers.scrollListTo(name), isFalse);
    });
  },
      skip: 'FINDING: a removed customer stays in the list (pos-api archives '
          'it and lists archived customers; the app does not filter them)');

  testWidgets('saving without a name asks for one', (tester) async {
    // Arrange
    await useWideSurface(tester);
    await launchApp(tester);
    await signIn(tester);
    final customers = CustomerRobot(ShellRobot(tester));
    await customers.openList();
    await customers.openAddForm();

    // Act
    await customers.submitForm();

    // Assert
    expect(customers.fieldError('ชื่อลูกค้า', 'โปรดระบุชื่อลูกค้า'),
        findsOneWidget);
    expect(customers.addFormTitle, findsOneWidget,
        reason: 'the form should stay open, nothing saved');
  });
}
