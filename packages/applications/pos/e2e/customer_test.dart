// A customer is added, found in the list, changed and removed through the
// customer pages under "จัดการ". Run with
// tools/e2e/run.sh <local|hosted> customer_test.dart.
//
// pos-api only archives a removed customer and the app keeps listing it, so
// the hosted target never removes one: it reuses the one kept customer
// "E2E customer" (see support/customer_plan.dart). The local target creates
// and removes its own run-named customer.

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'support/api/customer_api.dart';
import 'support/app.dart';
import 'support/cleanup.dart';
import 'support/customer_plan.dart';
import 'support/env.dart';
import 'support/robots/customer_robot.dart';
import 'support/robots/shell_robot.dart';
import 'support/run_data.dart';

/// Test data only; no real person has this number.
const _phone = '0800000000';
final _changedPhone = runPhone(E2EEnv.runId);

const _general = 'ลูกค้าทั่วไป';
const _wholesale = 'ลูกค้าขายส่ง';
const _typeRow = 'ประเภทลูกค้า';

const _addressRow = 'ที่อยู่';

const _removalLocalOnly = 'E2E: customer removal is checked on the local '
    'target only (a removed customer stays listed as archived); the kept '
    'customer is reused instead, its phone changed each run, and the edit '
    'also resets its type to ลูกค้าทั่วไป (FINDING, customer_edit_page.dart:59)';

void main() {
  initE2E();

  testWidgets('a customer can be added, seen, changed and removed',
      (tester) async {
    // Arrange
    final customers = await _openCustomers(tester);
    final plan = CustomerPlan.forTarget(
        hosted: E2EEnv.isHosted, runName: RunData.name('customer'));
    _registerCleanup(plan);

    // Act: add, unless the hosted target's kept customer exists already
    final (:customer, created: _) = await _ensureListed(customers, plan);

    // Assert
    expect(await customers.scrollListTo(plan.name, code: customer.code), isTrue,
        reason: 'the customer should be listed');

    // Act / Assert: detail and edit
    await _openAndCheck(customers, customer);
    await _changePhone(customers, customer);

    if (!plan.removes) {
      debugPrint(_removalLocalOnly);
      return;
    }

    // Act
    await customers.delete();
    await customers.reenterList();

    // Assert
    // FINDING: pos-api only archives a removed customer and lists archived
    // ones too, and the app does not filter them, so the customer is still
    // listed. Asserted as the app behaves; a skipped test below says what a
    // user expects. The server shows the removal was recorded.
    expect(await customers.scrollListTo(plan.name, code: customer.code), isTrue,
        reason: 'the app currently keeps listing a removed customer');
    expect(await _statusOf(customer), archivedStatus);
  });

  testWidgets(
      'the kept customer is created, marked, when absent and reused '
      'when present', (tester) async {
    // Arrange: no kept customer yet (local only: the hosted one is never
    // removed)
    final customers = await _openCustomers(tester);
    const plan = CustomerPlan.kept();
    await removeCustomersNamed(plan.name);
    Cleanup.add(plan.name, () => removeCustomersNamed(plan.name));

    // Act: the steps the hosted target runs, twice
    final first = await _ensureListed(customers, plan);
    final second = await _ensureListed(customers, plan);

    // Assert
    expect(first.created, isTrue, reason: 'none existed, so it is created');
    expect(second.created, isFalse, reason: 'then it is reused');
    expect(second.customer.code, first.customer.code);

    // Act / Assert: the marker is on the customer, and the edit keeps it
    await _openAndCheck(customers, second.customer);
    expect(
        customers.detailRow(_addressRow, keptCustomerMarker), findsOneWidget);
    await _changePhone(customers, second.customer);
    expect(
        customers.detailRow(_addressRow, keptCustomerMarker), findsOneWidget);
  }, skip: E2EEnv.isHosted);

  testWidgets('editing a wholesale customer\'s phone resets its type',
      (tester) async {
    // Arrange: a wholesale customer, made through the API (local only)
    final customers = await _openCustomers(tester);
    final name = RunData.name('customer wholesale');
    Cleanup.add(name, () => removeCustomersNamed(name));
    await createCustomer(name,
        phone: _phone, customerType: customerTypeWholesaler);
    await customers.reenterList();
    await customers.open(name);
    expect(customers.detailRow(_typeRow, _wholesale), findsOneWidget);

    // Act
    await customers.edit(phone: _changedPhone);

    // Assert
    // FINDING: the edit form starts on the first type and never loads the
    // customer's (customer_edit_page.dart:59, 117-122), so saving a phone
    // change also turns the customer general. A skipped test below says what
    // a user expects.
    expect(customers.detailRow('โทรศัพท์', _changedPhone), findsOneWidget);
    expect(customers.detailRow(_typeRow, _general), findsOneWidget,
        reason: 'the app currently resets the type on any edit');
  }, skip: E2EEnv.isHosted);

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
      final customers = await _openCustomers(tester);
      final name = RunData.name('customer listed at once');
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
      final customers = await _openCustomers(tester);
      final name = RunData.name('customer removed');
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

  // FINDING (Task 7): see the running type test above.
  group('customer type on edit', () {
    testWidgets('editing only the phone keeps the customer type',
        (tester) async {
      // Arrange
      final customers = await _openCustomers(tester);
      final name = RunData.name('customer wholesale');
      Cleanup.add(name, () => removeCustomersNamed(name));
      await customers.add(name, phone: _phone, type: _wholesale);
      await customers.reenterList();
      await customers.open(name);

      // Act
      await customers.edit(phone: _changedPhone);

      // Assert
      expect(customers.detailRow(_typeRow, _wholesale), findsOneWidget);
    });
  },
      skip: 'FINDING: editing a customer resets its type to ลูกค้าทั่วไป '
          '(customer_edit_page.dart:59)');

  testWidgets('saving without a name asks for one', (tester) async {
    // Arrange
    final customers = await _openCustomers(tester);
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

/// Launches the app, signs in as admin and opens the customer list.
Future<CustomerRobot> _openCustomers(WidgetTester tester) async {
  await launchApp(tester);
  await signIn(tester);
  final customers = CustomerRobot(ShellRobot(tester));
  await customers.openList();
  return customers;
}

/// Queued before the add: removing by name does nothing when nothing was
/// created, and a failure inside the add still cleans up. The kept customer
/// is reported instead, never removed.
void _registerCleanup(CustomerPlan plan) {
  if (plan.removes) {
    Cleanup.add(plan.name, () => removeCustomersNamed(plan.name));
  } else {
    Cleanup.keep('customer "${plan.name}"');
  }
}

/// Adds [plan]'s customer through the form, with the suite's marker, unless
/// the suite's own one is active; refuses (fails, touching nothing) when
/// only someone else's customer has the name. Then re-enters the list
/// (FINDING: on a wide screen it loads only on entry) and returns the
/// suite's customer as the server has it.
Future<({Customer customer, bool created})> _ensureListed(
    CustomerRobot customers, CustomerPlan plan) async {
  final decision = plan.decide(await _recordsNamed(plan.name));
  switch (decision) {
    case CreateCustomer():
      await customers.add(plan.name,
          phone: _phone, address: plan.markerOnCreate);
    case ReuseCustomer(:final code, :final ownedCount):
      if (ownedCount > 1) {
        debugPrint('E2E: $ownedCount kept customers found, using $code');
      }
      debugPrint('E2E: reusing customer "${plan.name}" ($code)');
    case RefuseCustomer(:final foreignCode):
      fail('A customer named "${plan.name}" exists that the E2E suite did '
          'not create (code $foreignCode); it was left untouched');
  }
  await customers.reenterList();
  final saved = plan.decide(await _recordsNamed(plan.name));
  if (saved is! ReuseCustomer) {
    fail('No active customer "${plan.name}" with the suite\'s marker');
  }
  final customer =
      (await customersNamed(plan.name)).firstWhere((c) => c.code == saved.code);
  return (customer: customer, created: decision is CreateCustomer);
}

Future<List<CustomerRecord>> _recordsNamed(String name) async => [
      for (final c in await customersNamed(name))
        (name: c.name, status: c.status, code: c.code, address: c.address),
    ];

/// Opens [customer] and checks the detail shows its name and phone.
Future<void> _openAndCheck(CustomerRobot customers, Customer customer) async {
  await customers.open(customer.name, code: customer.code);
  expect(customers.detailRow('ชื่อลูกค้า', customer.name), findsOneWidget);
  expect(customers.detailRow('โทรศัพท์', customer.phone), findsOneWidget);
}

/// From the open detail: changes the phone to the run's and checks the
/// detail shows it.
Future<void> _changePhone(CustomerRobot customers, Customer customer) async {
  await customers.edit(phone: _changedPhone);

  expect(customers.detailRow('โทรศัพท์', _changedPhone), findsOneWidget);
  expect(customers.detailRow('ชื่อลูกค้า', customer.name), findsOneWidget);
}

Future<String?> _statusOf(Customer customer) async =>
    (await customersNamed(customer.name))
        .where((c) => c.id == customer.id)
        .firstOrNull
        ?.status;
