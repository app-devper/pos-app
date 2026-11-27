// The customer a sale is rung up for, by Task 3's rule (customer_plan.dart):
// the local target creates a run-named one through the repository and
// removes it at the end; the hosted target reuses the one kept customer and
// never removes it, creating it (with the suite's marker) only if absent.

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'api/customer_api.dart';
import 'cleanup.dart';
import 'customer_plan.dart';
import 'env.dart';
import 'run_data.dart';

/// Test data only; no real person has this number.
const _phone = '0800000000';

/// Signed in as admin: the customer to sell to, active on the server.
Future<Customer> saleCustomer() async {
  final plan = CustomerPlan.forTarget(
      hosted: E2EEnv.isHosted, runName: RunData.name('sale customer'));
  if (plan.removes) {
    Cleanup.add(
        'customer "${plan.name}"', () => removeCustomersNamed(plan.name));
  } else {
    Cleanup.keep('customer "${plan.name}" (kept for reuse)');
  }
  switch (plan.decide(await _recordsNamed(plan.name))) {
    case CreateCustomer():
      await createCustomer(plan.name,
          phone: _phone, customerType: customerTypeGeneral);
    case ReuseCustomer():
      break;
    case RefuseCustomer(:final foreignCode):
      fail('A customer named "${plan.name}" exists that the E2E suite did '
          'not create (code $foreignCode); it was left untouched');
  }
  final saved = plan.decide(await _recordsNamed(plan.name));
  if (saved is! ReuseCustomer) {
    fail('No active customer "${plan.name}" with the suite\'s marker');
  }
  return (await customersNamed(plan.name))
      .firstWhere((c) => c.code == saved.code);
}

Future<List<CustomerRecord>> _recordsNamed(String name) async => [
      for (final c in await customersNamed(name))
        (name: c.name, status: c.status, code: c.code, address: c.address),
    ];
