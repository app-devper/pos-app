// Customer clean-up through the app's own repository: the same API calls the
// customer screens make, usable after the app has been unmounted.

// Package imports:
import 'package:common/injection.dart';

// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/repositories/customer_repository.dart';

/// pos-api's status for a removed customer: DELETE only archives it.
const archived = 'ARCHIVED';

/// Removes every customer named exactly [name] that is not removed yet;
/// does nothing when there is none (the test may already have removed it
/// through the screens).
///
/// pos-api has no hard delete, so a removed customer stays in the database,
/// archived; see the Task 3 report.
Future<void> removeCustomersNamed(String name) async {
  final repository = getIt()<CustomerRepository>();
  for (final customer in await _customersNamed(name)) {
    if (customer.status == archived) continue;
    await repository.removeCustomerById(customer.id);
  }
}

/// The status of each customer named exactly [name], as the server has it.
Future<List<String>> customerStatusesNamed(String name) async => [
      for (final customer in await _customersNamed(name)) customer.status,
    ];

/// getCustomers asks the server, not the repository's cached list.
Future<List<Customer>> _customersNamed(String name) async {
  final customers = await getIt()<CustomerRepository>().getCustomers();
  return customers.where((c) => c.name == name).toList();
}
