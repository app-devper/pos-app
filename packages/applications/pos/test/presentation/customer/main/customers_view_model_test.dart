import 'dart:async';

import 'package:common/core/error/exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/customer/param.dart';
import 'package:pos/domain/repositories/customer_repository.dart';
import 'package:pos/presentation/customer/main/customer_view_model.dart';
import 'package:pos/presentation/customer/main/customers_view_model.dart';

class FakeCustomerRepository implements CustomerRepository {
  final List<Customer> customers;
  final Customer? byId;
  final Object? throws;
  final Completer<List<Customer>>? pendingLocal;

  FakeCustomerRepository({
    this.customers = const [],
    this.byId,
    this.throws,
    this.pendingLocal,
  });

  @override
  Future<List<Customer>> getLocalCustomers() async {
    final pending = pendingLocal;
    if (pending != null) {
      return pending.future;
    }
    final error = throws;
    if (error != null) {
      throw error;
    }
    return customers;
  }

  @override
  Future<Customer> getCustomerById(String customerId) async {
    final error = throws;
    if (error != null) {
      throw error;
    }
    return byId ?? customers.first;
  }

  @override
  Future<Customer> createCustomer(CustomerParam param) =>
      throw UnimplementedError();

  @override
  Future<List<Customer>> getCustomers() => throw UnimplementedError();

  @override
  Future<Customer> getCustomerByCode(String customerCode) =>
      throw UnimplementedError();

  @override
  Future<Customer> updateCustomerById(String customerId, CustomerParam param) =>
      throw UnimplementedError();

  @override
  Future<Customer> removeCustomerById(String customerId) =>
      throw UnimplementedError();
}

Customer buildCustomer(String id,
    {String status = 'ACTIVE', String? name, String? code, String phone = ''}) {
  return Customer(
    id: id,
    code: code ?? 'code-$id',
    name: name ?? 'name-$id',
    address: '',
    phone: phone,
    email: '',
    status: status,
    type: 'GENERAL',
  );
}

CustomersViewModel buildCustomersViewModel(CustomerRepository repo) {
  return CustomersViewModel(
    customerRepo: repo,
  );
}

CustomerViewModel buildCustomerViewModel(CustomerRepository repo) {
  return CustomerViewModel(
    customerRepo: repo,
  );
}

void main() {
  group('CustomersViewModel', () {
    test('getCustomers populates items from the local cache', () async {
      final vm = buildCustomersViewModel(
          FakeCustomerRepository(customers: [buildCustomer('1')]));

      await vm.getCustomers();

      expect(vm.state.value.loading, isFalse);
      expect(vm.state.value.items, hasLength(1));
    });

    test('a removed (archived) customer is not listed', () async {
      // Arrange
      final vm = buildCustomersViewModel(FakeCustomerRepository(customers: [
        buildCustomer('kept'),
        buildCustomer('removed', status: 'ARCHIVED'),
      ]));

      // Act
      await vm.getCustomers();

      // Assert
      expect(vm.state.value.items.map((c) => c.id), ['kept']);
    });

    test('getCustomers maps a typed exception to state.error', () async {
      final vm = buildCustomersViewModel(
        FakeCustomerRepository(
            throws: const NetworkException(message: 'offline')),
      );

      await vm.getCustomers();

      expect(vm.state.value.error, isNotNull);
      expect(vm.state.value.items, isEmpty);
    });
  });

  group('CustomersViewModel search', () {
    final shop = [
      buildCustomer('1', name: 'Somchai Shop', code: 'CU001', phone: '0811'),
      buildCustomer('2', name: 'สมหญิง', code: 'CU002', phone: '0899'),
      buildCustomer('3', name: 'Old', code: 'CU003', status: 'ARCHIVED'),
    ];

    Future<CustomersViewModel> loaded() async {
      final vm =
          buildCustomersViewModel(FakeCustomerRepository(customers: shop));
      await vm.getCustomers();
      return vm;
    }

    test('matches the name ignoring case', () async {
      final vm = await loaded();

      vm.search('SOMCHAI');

      expect(vm.state.value.items.map((c) => c.id), ['1']);
    });

    test('matches the code ignoring case', () async {
      final vm = await loaded();

      vm.search('cu002');

      expect(vm.state.value.items.map((c) => c.id), ['2']);
    });

    test('matches the phone', () async {
      final vm = await loaded();

      vm.search('0899');

      expect(vm.state.value.items.map((c) => c.id), ['2']);
    });

    test('a query of only spaces is no search: it lists everyone', () async {
      final vm = await loaded();

      vm.search('   ');

      expect(vm.isSearching, isFalse,
          reason: 'an empty list then reads ยังไม่มีลูกค้า, not "no match"');
      expect(vm.state.value.items.map((c) => c.id), ['1', '2']);
      vm.search(' สม ');
      expect(vm.isSearching, isTrue);
    });

    test('never brings back a removed customer', () async {
      final vm = await loaded();

      vm.search('cu003');

      expect(vm.state.value.items, isEmpty);
    });

    test('an empty search lists every customer, and a reload keeps the search',
        () async {
      final vm = await loaded();
      vm.search('สม');

      await vm.reload();

      expect(vm.state.value.items.map((c) => c.id), ['2']);
      vm.search('');
      expect(vm.state.value.items.map((c) => c.id), ['1', '2']);
    });
  });

  group('CustomerViewModel', () {
    test('a lookup emits the customer once', () async {
      final vm = buildCustomerViewModel(
          FakeCustomerRepository(byId: buildCustomer('7')));
      final loaded = <Customer>[];
      vm.loaded.listen(loaded.add);

      await vm.getCustomerById('7');
      await Future<void>.delayed(Duration.zero);

      expect(vm.state.value.loading, isFalse);
      expect(loaded.single.id, '7');
    });

    test('a failed lookup reaches the screen instead of going nowhere',
        () async {
      // The page only listened for the result, so a failure left the panel
      // unchanged and told the user nothing.
      final vm = buildCustomerViewModel(
        FakeCustomerRepository(
            throws: const NotFoundException(message: 'missing')),
      );
      final loaded = <Customer>[];
      final errors = <String>[];
      vm.loaded.listen(loaded.add);
      vm.errors.listen(errors.add);

      await vm.getCustomerById('x');
      await Future<void>.delayed(Duration.zero);

      expect(errors, hasLength(1));
      expect(loaded, isEmpty);
    });
  });

  test('a load that finishes after dispose changes nothing and does not throw',
      () async {
    final pending = Completer<List<Customer>>();
    final vm = buildCustomersViewModel(
      FakeCustomerRepository(pendingLocal: pending),
    );

    final load = vm.getCustomers();
    vm.dispose();
    pending.complete([buildCustomer('1')]);

    await expectLater(load, completes);
    expect(vm.state.value.items, isEmpty);
    expect(vm.state.value.loading, isTrue);
  });
}
