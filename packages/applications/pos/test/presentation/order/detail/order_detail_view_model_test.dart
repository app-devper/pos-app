import 'dart:async';

import 'package:um/domain/usecase/auth_use_cases.dart';
import 'package:common/core/error/exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/domain/repositories/customer_repository.dart';
import 'package:pos/domain/repositories/order_repository.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/supplier_repository.dart';
import 'package:pos/presentation/order/detail/order_detail_state.dart';
import 'package:pos/presentation/order/detail/order_detail_view_model.dart';
import 'package:um/domain/entities/auth/passkey.dart';
import 'package:um/domain/entities/auth/session.dart';
import 'package:um/domain/repositories/login_repository.dart';

class FakeLoginRepository implements LoginRepository {
  @override
  Future<PasskeyChallenge> passkeyLoginOptions(String system) =>
      throw UnimplementedError();

  @override
  Future<Session> loginWithPasskey({
    required String ceremonyId,
    required String credentialJson,
    required String system,
    String typedUsername = '',
  }) =>
      throw UnimplementedError();

  final String role;
  final Object? getRoleThrows;

  FakeLoginRepository({this.role = 'USER', this.getRoleThrows});

  @override
  Future<String> getRole() async {
    final error = getRoleThrows;
    if (error != null) {
      throw error;
    }
    return role;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Answers the role only when the test completes [role].
class PendingRoleRepository extends FakeLoginRepository {
  final pending = Completer<String>();

  @override
  Future<String> getRole() => pending.future;
}

class FakeOrderRepository implements OrderRepository {
  final OrderDetail? orderDetail;
  final OrderItemDetail? removedItem;
  final Object? getByIdThrows;
  final Object? removeThrows;
  final Object? removeItemThrows;

  final List<String> loadedOrderIds = [];
  final List<String> removedOrderIds = [];
  final List<String> removedItemIds = [];

  FakeOrderRepository({
    this.orderDetail,
    this.removedItem,
    this.getByIdThrows,
    this.removeThrows,
    this.removeItemThrows,
  });

  @override
  Future<OrderDetail> getOrderById(String orderId) async {
    final error = getByIdThrows;
    if (error != null) {
      throw error;
    }
    loadedOrderIds.add(orderId);
    return orderDetail!;
  }

  @override
  Future<OrderDetail> removeOrderById(String orderId) async {
    final error = removeThrows;
    if (error != null) {
      throw error;
    }
    removedOrderIds.add(orderId);
    return orderDetail!;
  }

  @override
  Future<OrderItemDetail> removeOrderItemById(String itemId) async {
    final error = removeItemThrows;
    if (error != null) {
      throw error;
    }
    removedItemIds.add(itemId);
    return removedItem!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Serves the document once and then goes offline, so a refresh can fail while
/// the screen already has something on it.
class FailOnSecondLoadRepository implements OrderRepository {
  final OrderDetail orderDetail;
  int _calls = 0;

  FailOnSecondLoadRepository(this.orderDetail);

  @override
  Future<OrderDetail> getOrderById(String orderId) async {
    if (_calls++ > 0) {
      throw const NetworkException(message: 'offline');
    }
    return orderDetail;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeCustomerRepository implements CustomerRepository {
  final List<Customer> customers;
  final Object? throws;

  FakeCustomerRepository({this.customers = const [], this.throws});

  @override
  Future<List<Customer>> getLocalCustomers() async {
    final error = throws;
    if (error != null) {
      throw error;
    }
    return customers;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeSupplierRepository implements SupplierRepository {
  final Supplier? supplier;
  final Object? throws;

  FakeSupplierRepository({this.supplier, this.throws});

  @override
  Future<Supplier> getSupplierInfo() async {
    final error = throws;
    if (error != null) {
      throw error;
    }
    return supplier!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Customer _buildCustomer(String code) {
  return Customer(
    id: 'c1',
    code: code,
    name: 'Test Customer',
    address: '',
    phone: '',
    email: '',
    status: 'Active',
    type: 'General',
  );
}

Supplier _buildSupplier() {
  return Supplier(
      id: 's1', name: 'Test Supplier', address: '', phone: '', taxId: '');
}

OrderItemDetail _buildOrderItem(String id) {
  return OrderItemDetail(
    id: id,
    product: null,
    quantity: 1,
    price: 10,
    costPrice: 5,
    discount: 0,
    createdDate: '2026-01-01T00:00:00.000Z',
    order: null,
  );
}

OrderDetail _buildOrderDetail(String id,
    {List<OrderItemDetail> items = const []}) {
  return OrderDetail(
    id: id,
    createdDate: '2026-01-01T00:00:00.000Z',
    items: items,
    total: 100,
    totalCost: 50,
    discount: 0,
    type: 'Cash',
    code: 'O-1',
    customerCode: 'CUST-1',
    customerName: 'Test Customer',
  );
}

/// The product catalogue: [products] by id, or [throws] for every lookup.
class FakeCatalogueRepository implements ProductRepository {
  final Map<String, Product> products;
  final Object? throws;

  FakeCatalogueRepository({this.products = const {}, this.throws});

  @override
  Future<Product?> getLocalProductById(String productId) async {
    final error = throws;
    if (error != null) throw error;
    return products[productId];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ProductUnit _unitOf(String id, String name) => ProductUnit(
    id: id,
    productId: 'p1',
    costPrice: 1,
    unit: name,
    size: 1,
    barcode: '',
    volume: 0,
    volumeUnit: '');

Product _productWithUnits(List<ProductUnit> units) => Product(
    id: 'p1',
    name: 'Product',
    status: 'ACTIVE',
    category: 'General',
    createdDate: '',
    units: units,
    prices: const [],
    stocks: const []);

OrderItemDetail _lineIn(String id, String unitId) => OrderItemDetail(
    id: id,
    product: _productWithUnits(const []),
    unitId: unitId,
    quantity: 2,
    price: 50,
    costPrice: 20,
    discount: 0,
    createdDate: '2026-01-01T00:00:00.000Z',
    order: null);

OrderDetailViewModel _buildViewModel({
  LoginRepository? loginRepo,
  OrderRepository? orderRepo,
  CustomerRepository? customerRepo,
  SupplierRepository? supplierRepo,
  ProductRepository? productRepo,
}) {
  return OrderDetailViewModel(
    productRepo: productRepo ?? FakeCatalogueRepository(),
    getRoleUseCase: GetRoleUseCase(loginRepo ?? FakeLoginRepository()),
    orderRepo: orderRepo ?? FakeOrderRepository(),
    supplierRepo: supplierRepo ?? FakeSupplierRepository(),
    customerRepo: customerRepo ?? FakeCustomerRepository(),
  );
}

void main() {
  group('checkLogin', () {
    test('the role answer keeps the bill loaded while it was awaited',
        () async {
      // Arrange: the page asks for the role and the bill together
      final login = PendingRoleRepository();
      final bill = _buildOrderDetail('order-1');
      final vm = _buildViewModel(
          loginRepo: login, orderRepo: FakeOrderRepository(orderDetail: bill));

      // Act: the bill arrives first, then the role
      final roleRead = vm.checkLogin();
      await vm.getOrderById('order-1');
      login.pending.complete('ADMIN');
      await roleRead;

      // Assert
      expect(vm.state.value.isAdmin, isTrue);
      expect(vm.state.value.order, same(bill),
          reason: 'the role must not write back the state from before');
      expect(vm.state.value.loading, isFalse);
    });

    test('an admin gets the admin actions', () async {
      final vm = _buildViewModel(loginRepo: FakeLoginRepository(role: 'ADMIN'));

      await vm.checkLogin();

      expect(vm.state.value.isAdmin, isTrue);
    });

    test('SUPER gets them too, as pos-api allows', () async {
      final vm = _buildViewModel(loginRepo: FakeLoginRepository(role: 'SUPER'));

      await vm.checkLogin();

      expect(vm.state.value.isAdmin, isTrue);
    });

    test('any role below ADMIN does not', () async {
      final vm = _buildViewModel(loginRepo: FakeLoginRepository(role: 'USER'));

      await vm.checkLogin();

      expect(vm.state.value.isAdmin, isFalse);
    });

    test('a role that cannot be read leaves the screen as a cashier', () async {
      final vm = _buildViewModel(
        loginRepo: FakeLoginRepository(
            getRoleThrows: const NetworkException(message: 'offline')),
      );
      final errors = <String>[];
      vm.errors.listen(errors.add);

      await vm.checkLogin();
      await _pump();

      expect(vm.state.value.isAdmin, isFalse,
          reason: 'an unreadable role must not unlock deleting orders');
      expect(errors, isEmpty);
    });
  });

  group('getOrderById', () {
    test('puts the document on the screen', () async {
      final orderDetail = _buildOrderDetail('order-1');
      final vm = _buildViewModel(
          orderRepo: FakeOrderRepository(orderDetail: orderDetail));

      await vm.getOrderById('order-1');

      expect(vm.state.value.loading, isFalse);
      expect(vm.state.value.order, orderDetail);
    });

    test('a failure is reported and stops the spinner', () async {
      final vm = _buildViewModel(
        orderRepo: FakeOrderRepository(
            getByIdThrows: const NetworkException(message: 'offline')),
      );
      final errors = <String>[];
      vm.errors.listen(errors.add);

      await vm.getOrderById('order-1');
      await _pump();

      expect(vm.state.value.loading, isFalse);
      expect(errors, hasLength(1));
    });

    test('a failed reload keeps the document already on screen', () async {
      final repo = FailOnSecondLoadRepository(_buildOrderDetail('order-1'));
      final vm = _buildViewModel(orderRepo: repo);
      final errors = <String>[];
      vm.errors.listen(errors.add);

      await vm.getOrderById('order-1');
      await vm.getOrderById('order-1');
      await _pump();

      expect(errors, hasLength(1));
      expect(vm.state.value.order, isNotNull,
          reason: 'a failed refresh must not blank the order the user is '
              'reading');
    });
  });

  group('the lines\' units', () {
    test('each line\'s unit is named from the product catalogue', () async {
      // Arrange
      final bill = _buildOrderDetail('o1',
          items: [_lineIn('i1', 'u1'), _lineIn('i2', 'u2')]);
      final vm = _buildViewModel(
          orderRepo: FakeOrderRepository(orderDetail: bill),
          productRepo: FakeCatalogueRepository(products: {
            'p1': _productWithUnits(
                [_unitOf('u1', 'ชิ้น'), _unitOf('u2', 'แผง')]),
          }));

      // Act
      await vm.getOrderById('o1');

      // Assert
      final state = vm.state.value;
      expect(state.items.map(state.unitNameOf), ['ชิ้น', 'แผง']);
    });

    test('a catalogue that fails is said, and the bill is still shown',
        () async {
      // Arrange
      final bill = _buildOrderDetail('o1', items: [_lineIn('i1', 'u1')]);
      final vm = _buildViewModel(
          orderRepo: FakeOrderRepository(orderDetail: bill),
          productRepo: FakeCatalogueRepository(
              throws: const ServerException(message: 'catalogue down')));
      final errors = <String>[];
      vm.errors.listen(errors.add);

      // Act
      await vm.getOrderById('o1');
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(vm.state.value.order, same(bill));
      expect(vm.state.value.unitNameOf(bill.items.first), isEmpty);
      expect(errors, hasLength(1));
    });
  });

  group('the bill totals', () {
    OrderItemDetail line(String id,
            {required double price,
            required double cost,
            String status = 'CONFIRMED'}) =>
        OrderItemDetail(
          id: id,
          product: null,
          quantity: 1,
          price: price,
          costPrice: cost,
          discount: 0,
          createdDate: '2026-01-01T00:00:00.000Z',
          order: null,
          status: status,
        );

    test('a cancelled line counts in neither the total, the cost nor profit',
        () async {
      // Arrange
      final bill = _buildOrderDetail('o1', items: [
        line('i1', price: 30, cost: 10),
        line('i2', price: 20, cost: 8, status: 'CANCELLED'),
      ]);
      final vm =
          _buildViewModel(orderRepo: FakeOrderRepository(orderDetail: bill));

      // Act
      await vm.getOrderById('o1');

      // Assert
      final state = vm.state.value;
      expect(state.items, hasLength(2), reason: 'the line is still shown');
      expect(state.total, 30);
      expect(state.totalCost, 10);
      // The profit the bill shows (BillSummary: total - cost).
      expect(state.total - state.totalCost, 20);
    });
  });

  group('removeOrderById', () {
    test('announces the removal so the screen can pop with it', () async {
      final orderDetail = _buildOrderDetail('order-1');
      final vm = _buildViewModel(
          orderRepo: FakeOrderRepository(orderDetail: orderDetail));
      final removals = <OrderDetail>[];
      vm.removals.listen(removals.add);

      await vm.removeOrderById('order-1');
      await _pump();

      expect(removals, [orderDetail]);
      expect(vm.state.value.loading, isFalse);
    });

    test('a failure is reported and nothing is removed', () async {
      final vm = _buildViewModel(
        orderRepo: FakeOrderRepository(
            removeThrows: const NetworkException(message: 'offline')),
      );
      final removals = <OrderDetail>[];
      final errors = <String>[];
      vm.removals.listen(removals.add);
      vm.errors.listen(errors.add);

      await vm.removeOrderById('order-1');
      await _pump();

      expect(errors, hasLength(1));
      expect(removals, isEmpty);
    });
  });

  group('removeOrderItem', () {
    test('reloads the document, because every total on it changed', () async {
      final repo = FakeOrderRepository(
        orderDetail: _buildOrderDetail('order-1'),
        removedItem: _buildOrderItem('item-1'),
      );
      final vm = _buildViewModel(orderRepo: repo);

      await vm.removeOrderItem('order-1', 'item-1');

      expect(repo.removedItemIds, ['item-1']);
      expect(repo.loadedOrderIds, ['order-1'],
          reason: 'the reload used to be a second call the page made itself');
      expect(vm.state.value.order, isNotNull);
      expect(vm.state.value.loading, isFalse);
    });

    test('a failed delete is reported and does not reload', () async {
      final repo = FakeOrderRepository(
        orderDetail: _buildOrderDetail('order-1'),
        removeItemThrows: const NetworkException(message: 'offline'),
      );
      final vm = _buildViewModel(orderRepo: repo);
      final errors = <String>[];
      vm.errors.listen(errors.add);

      await vm.removeOrderItem('order-1', 'item-1');
      await _pump();

      expect(errors, hasLength(1));
      expect(repo.loadedOrderIds, isEmpty);
      expect(vm.state.value.loading, isFalse,
          reason: 'the screen must not be left holding a spinner');
    });
  });

  group('getSupplier', () {
    test('resolves both the matching customer and the shop profile', () async {
      final vm = _buildViewModel(
        customerRepo: FakeCustomerRepository(
            customers: [_buildCustomer('CUST-1'), _buildCustomer('CUST-2')]),
        supplierRepo: FakeSupplierRepository(supplier: _buildSupplier()),
      );
      final receipts = <SupplierResult>[];
      vm.receipts.listen(receipts.add);

      await vm.getSupplier('CUST-1');
      await _pump();

      expect(receipts, hasLength(1));
      expect(receipts.single.customer!.code, 'CUST-1');
      expect(receipts.single.supplier.id, 's1');
    });

    test('prints without a customer when no code matches', () async {
      final vm = _buildViewModel(
        customerRepo:
            FakeCustomerRepository(customers: [_buildCustomer('OTHER')]),
        supplierRepo: FakeSupplierRepository(supplier: _buildSupplier()),
      );
      final receipts = <SupplierResult>[];
      vm.receipts.listen(receipts.add);

      await vm.getSupplier('CUST-1');
      await _pump();

      expect(receipts.single.customer, isNull);
    });

    test('prints without a customer when the customer lookup throws', () async {
      final vm = _buildViewModel(
        customerRepo: FakeCustomerRepository(
            throws: const NetworkException(message: 'offline')),
        supplierRepo: FakeSupplierRepository(supplier: _buildSupplier()),
      );
      final receipts = <SupplierResult>[];
      vm.receipts.listen(receipts.add);

      await vm.getSupplier('CUST-1');
      await _pump();

      expect(receipts, hasLength(1),
          reason: 'the name can still be typed into the dialog');
    });

    test('no shop profile yet sends the user to create one', () async {
      final vm = _buildViewModel(
        supplierRepo: FakeSupplierRepository(
            throws: const NotFoundException(message: 'no supplier')),
      );
      final setups = <void>[];
      final errors = <String>[];
      vm.supplierSetups.listen(setups.add);
      vm.errors.listen(errors.add);

      await vm.getSupplier('CUST-1');
      await _pump();

      expect(setups, hasLength(1));
      expect(errors, isEmpty, reason: 'nothing has gone wrong');
    });

    test('being offline is reported, not treated as a missing profile',
        () async {
      final vm = _buildViewModel(
        supplierRepo: FakeSupplierRepository(
            throws: const NetworkException(message: 'offline')),
      );
      final setups = <void>[];
      final errors = <String>[];
      vm.supplierSetups.listen(setups.add);
      vm.errors.listen(errors.add);

      await vm.getSupplier('CUST-1');
      await _pump();

      expect(errors, hasLength(1));
      expect(setups, isEmpty,
          reason: 'the old code opened the setup form, where the user found '
              'their profile already filled in and no explanation');
    });
  });

  test('a command is refused while another is in flight', () async {
    final repo = FakeOrderRepository(orderDetail: _buildOrderDetail('order-1'));
    final vm = _buildViewModel(orderRepo: repo);

    final first = vm.getOrderById('order-1');
    await vm.removeOrderById('order-1');
    await first;

    expect(repo.removedOrderIds, isEmpty,
        reason: 'a delete must not start while the document is still loading');
  });
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);
