// Customer clean-up through the app's own repository: the same API calls the
// customer screens make, usable after the app has been unmounted.

// Package imports:
import 'package:common/injection.dart';

// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/customer/param.dart';
import 'package:pos/domain/repositories/customer_repository.dart';
import '../customer_plan.dart';

/// Removes every customer named exactly [name] that is not removed yet;
/// does nothing when there is none (the test may already have removed it
/// through the screens).
///
/// pos-api has no hard delete, so a removed customer stays in the database,
/// archived; see the Task 3 report.
Future<void> removeCustomersNamed(String name) async {
  final repository = getIt()<CustomerRepository>();
  for (final customer in await customersNamed(name)) {
    if (customer.status == archivedStatus) continue;
    await repository.removeCustomerById(customer.id);
  }
}

/// Creates a customer the way the add form does, without the screens; for
/// arranging a test that starts from an existing customer.
Future<Customer> createCustomer(
  String name, {
  required String phone,
  required String customerType,
}) =>
    getIt()<CustomerRepository>().createCustomer(CustomerParam(
      name: name,
      address: '',
      phone: phone,
      email: '',
      customerType: customerType,
    ));

/// Every customer named exactly [name], removed ones included, as the
/// server has them (getCustomers asks the server, not the cache).
Future<List<Customer>> customersNamed(String name) async {
  final customers = await getIt()<CustomerRepository>().getCustomers();
  return customers.where((c) => c.name == name).toList();
}
