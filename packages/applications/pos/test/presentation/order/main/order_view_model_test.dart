import 'dart:async';

import 'package:um/domain/usecase/auth_use_cases.dart';
import 'package:common/core/error/exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/model/order/order_summary.dart';
import 'package:pos/domain/model/order/param.dart';
import 'package:pos/domain/repositories/order_repository.dart';
import 'package:pos/presentation/order/main/order_ui_model.dart';
import 'package:pos/presentation/order/main/order_state.dart';
import 'package:pos/presentation/order/main/order_view_model.dart';
import 'package:um/domain/entities/auth/login.dart';
import 'package:um/domain/entities/auth/param.dart';
import 'package:um/domain/entities/auth/session.dart';
import 'package:um/domain/entities/auth/system.dart' as um;
import 'package:um/domain/entities/auth/user_session.dart';
import 'package:um/domain/entities/auth/passkey.dart';
import 'package:um/domain/repositories/login_repository.dart';

OrderSummary order(String id, String type,
    {double total = 100, double cost = 60, String status = 'CONFIRMED'}) {
  return OrderSummary(
    id: id,
    code: 'OD-$id',
    customerCode: 'C1',
    customerName: 'ลูกค้า',
    createdDate: '2026-09-01T00:00:00Z',
    total: total,
    totalCost: cost,
    discount: 0,
    type: type,
    status: status,
  );
}

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({this.orders = const [], this.throws});

  final List<OrderSummary> orders;
  Object? throws;

  @override
  Future<List<OrderSummary>> getOrderRange(GetOrderRangeParam param) async {
    final error = throws;
    if (error != null) throw error;
    return orders;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Answers each list request only when the test completes it, in any order.
class ScriptedOrderRepository implements OrderRepository {
  final pending = <Completer<List<OrderSummary>>>[];

  @override
  Future<List<OrderSummary>> getOrderRange(GetOrderRangeParam param) {
    final load = Completer<List<OrderSummary>>();
    pending.add(load);
    return load.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Answers the role only when the test completes [pending].
class PendingRoleRepository extends FakeLoginRepository {
  final pending = Completer<String>();

  @override
  Future<String> getRole() => pending.future;
}

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

  @override
  Future<Session> exchangeTicket(String ticket, String system) =>
      throw UnimplementedError();

  FakeLoginRepository({this.role = 'USER', this.throws});

  final String role;
  final Object? throws;

  @override
  Future<String> getRole() async {
    final error = throws;
    if (error != null) throw error;
    return role;
  }

  @override
  Future<Session> loginUser(LoginParam param) => throw UnimplementedError();

  @override
  Future<Login> keepAlive() => throw UnimplementedError();

  @override
  Future<bool> logoutUser() => throw UnimplementedError();

  @override
  Future<um.System> getSystem() => throw UnimplementedError();

  @override
  String getClientId() => 'C1';

  @override
  Future<List<UserSession>> getSessions() => throw UnimplementedError();

  @override
  Future<bool> revokeSessionById(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<int> revokeOtherSessions() => throw UnimplementedError();
}

OrderViewModel buildViewModel({
  OrderRepository? orders,
  FakeLoginRepository? login,
}) {
  return OrderViewModel(
    orderRepo: orders ?? FakeOrderRepository(),
    getRoleUseCase: GetRoleUseCase(login ?? FakeLoginRepository()),
  );
}

GetOrderRangeParam anyRange() =>
    GetOrderRangeParam(startDate: '2026-09-01', endDate: '2026-09-02');

void main() {
  group('filtering by channel', () {
    final mixed = [
      order('1', 'Cash'),
      order('2', 'Online'),
      order('3', ''),
      order('4', 'Cash'),
    ];

    test('Store covers cash sales and the ones with no channel recorded',
        () async {
      final viewModel =
          buildViewModel(orders: FakeOrderRepository(orders: mixed));

      await viewModel.getOrderItem('Store', anyRange());

      // An order saved before the channel existed has an empty type; it was
      // rung up at the counter, so it belongs with the store sales.
      expect(viewModel.state.value.orders!.map((e) => e.id), ['1', '3', '4']);
    });

    test('Online covers only the online channel', () async {
      final viewModel =
          buildViewModel(orders: FakeOrderRepository(orders: mixed));

      await viewModel.getOrderItem('Online', anyRange());

      expect(viewModel.state.value.orders!.map((e) => e.id), ['2']);
    });

    test('any other type keeps every order', () async {
      final viewModel =
          buildViewModel(orders: FakeOrderRepository(orders: mixed));

      await viewModel.getOrderItem('All', anyRange());

      expect(viewModel.state.value.orders, hasLength(4));
    });
  });

  test('the totals count the filtered orders, not everything fetched',
      () async {
    final viewModel = buildViewModel(
      orders: FakeOrderRepository(orders: [
        order('1', 'Cash', total: 100, cost: 60),
        order('2', 'Online', total: 999, cost: 999),
        order('3', '', total: 50, cost: 20),
      ]),
    );

    await viewModel.getOrderItem('Store', anyRange());

    expect(viewModel.state.value.total, 150);
    expect(viewModel.state.value.totalCost, 80);
  });

  test('a cancelled bill stays listed but counts in no total', () async {
    // Arrange
    final viewModel = buildViewModel(
      orders: FakeOrderRepository(orders: [
        order('1', 'Cash', total: 50, cost: 20),
        order('2', 'Cash', total: 50, cost: 20, status: 'CANCELLED'),
      ]),
    );

    // Act
    await viewModel.getOrderItem('All', anyRange());

    // Assert
    final state = viewModel.state.value;
    expect(state.orders!.map((e) => e.id), ['1', '2']);
    expect(state.total, 50);
    expect(state.totalCost, 20);
    // The profit the bills screen shows (BillSummary: total - cost).
    expect(state.total - state.totalCost, 30);
  });

  test('an older list that answers last does not replace the newer one',
      () async {
    // Arrange: "Yesterday" asked, then "Today"; Today answers first
    final repo = ScriptedOrderRepository();
    final viewModel = buildViewModel(orders: repo);
    final yesterday = viewModel.getOrderItem('All', anyRange());
    final today = viewModel.getOrderItem('All', anyRange());

    // Act
    repo.pending[1].complete([order('today', 'Cash', total: 30, cost: 10)]);
    await today;
    repo.pending[0]
        .complete([order('yesterday', 'Cash', total: 999, cost: 500)]);
    await yesterday;

    // Assert
    final state = viewModel.state.value;
    expect(state.orders!.map((e) => e.id), ['today']);
    expect(state.total, 30);
    expect(state.totalCost, 10);
  });

  test('an older load that fails after a newer list is shown says nothing',
      () async {
    // Arrange
    final repo = ScriptedOrderRepository();
    final viewModel = buildViewModel(orders: repo);
    final errors = <String>[];
    viewModel.errors.listen(errors.add);
    final older = viewModel.getOrderItem('All', anyRange());
    final newer = viewModel.getOrderItem('All', anyRange());

    // Act
    repo.pending[1].complete([order('today', 'Cash')]);
    await newer;
    repo.pending[0].completeError(
        const NetworkException(message: 'down', code: 'NETWORK_ERROR'));
    await older;
    await Future<void>.delayed(Duration.zero);

    // Assert
    expect(errors, isEmpty);
    expect(viewModel.state.value.orders!.map((e) => e.id), ['today']);
  });

  test('a failed refresh reports the error and keeps what is on screen',
      () async {
    final repo = FakeOrderRepository(orders: [order('1', 'Cash')]);
    final viewModel = buildViewModel(orders: repo);

    final errors = <String>[];
    viewModel.errors.listen(errors.add);

    await viewModel.getOrderItem('Store', anyRange());
    expect(viewModel.state.value.orders, hasLength(1));

    repo.throws =
        const NetworkException(message: 'down', code: 'NETWORK_ERROR');
    await viewModel.getOrderItem('Store', anyRange());
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, contains('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'));
    // The list a cashier was reading stays put; a dropped connection should
    // not blank the screen.
    expect(viewModel.state.value.orders, hasLength(1));
  });

  group('checkLogin', () {
    test('ADMIN and above count as admin for this screen', () async {
      final admin = buildViewModel(login: FakeLoginRepository(role: 'ADMIN'));
      final superuser =
          buildViewModel(login: FakeLoginRepository(role: 'SUPER'));
      final manager =
          buildViewModel(login: FakeLoginRepository(role: 'MANAGER'));
      final cashier = buildViewModel(login: FakeLoginRepository(role: 'USER'));

      await admin.checkLogin();
      await superuser.checkLogin();
      await manager.checkLogin();
      await cashier.checkLogin();

      expect(admin.state.value.isAdmin, isTrue);
      expect(superuser.state.value.isAdmin, isTrue);
      expect(manager.state.value.isAdmin, isFalse);
      expect(cashier.state.value.isAdmin, isFalse);
    });

    test('the role answer keeps the ranges set while it was awaited', () async {
      // Arrange: the page calls checkLogin, then initData, without waiting
      final viewModel =
          buildViewModel(login: FakeLoginRepository(role: 'ADMIN'));

      // Act
      final roleRead = viewModel.checkLogin();
      viewModel.initData();
      await roleRead;

      // Assert
      expect(viewModel.state.value.isAdmin, isTrue);
      expect(viewModel.state.value.ranges, isNotEmpty,
          reason: 'the admin gets the date-range dropdown');
    });

    test('a role answer after the page is left writes nothing', () async {
      // Arrange: the bills page is left while the role is still awaited
      final login = PendingRoleRepository();
      final viewModel = buildViewModel(login: login);
      final roleRead = viewModel.checkLogin();
      var notified = 0;
      viewModel.state.addListener(() => notified++);
      viewModel.dispose();

      // Act
      login.pending.complete('ADMIN');

      // Assert
      await expectLater(roleRead, completes);
      expect(viewModel.state.value.isAdmin, isFalse);
      expect(notified, 0);
    });

    test('an unreadable role stays a cashier, as every screen treats it',
        () async {
      final viewModel = buildViewModel(
        login: FakeLoginRepository(
          throws: const AuthException(message: 'expired', code: 'AU-401'),
        ),
      );
      final errors = <String>[];
      viewModel.errors.listen(errors.add);

      await viewModel.checkLogin();
      await Future<void>.delayed(Duration.zero);

      expect(errors, isEmpty,
          reason: 'the home menu never reported it; one rule for all screens');
      expect(viewModel.state.value.isAdmin, isFalse,
          reason: 'an unknown role must not unlock the admin actions');
    });
  });

  group('date ranges', () {
    DateTime midnight() {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }

    test('today spans midnight to midnight', () async {
      final viewModel = buildViewModel();

      final selections = <OrderRangeSelection>[];
      viewModel.rangeSelections.listen(selections.add);

      viewModel.selectRange(Range.today);
      await Future<void>.delayed(Duration.zero);

      final selection = selections.single;
      expect(selection.startDate, midnight());
      expect(selection.endDate, midnight().add(const Duration(days: 1)));
    });

    test('yesterday ends where today begins', () async {
      final viewModel = buildViewModel();

      final selections = <OrderRangeSelection>[];
      viewModel.rangeSelections.listen(selections.add);

      viewModel.selectRange(Range.yesterday);
      await Future<void>.delayed(Duration.zero);

      final selection = selections.single;
      expect(selection.startDate, midnight().subtract(const Duration(days: 1)));
      expect(selection.endDate, midnight());
    });

    test('current month runs from the first to the first of the next',
        () async {
      final viewModel = buildViewModel();
      final now = DateTime.now();

      final selections = <OrderRangeSelection>[];
      viewModel.rangeSelections.listen(selections.add);

      viewModel.selectRange(Range.currentMonth);
      await Future<void>.delayed(Duration.zero);

      final selection = selections.single;
      expect(selection.startDate, DateTime(now.year, now.month, 1));
      expect(selection.endDate, DateTime(now.year, now.month + 1, 1));
    });

    test('last month ends where the current one begins', () async {
      final viewModel = buildViewModel();
      final now = DateTime.now();

      final selections = <OrderRangeSelection>[];
      viewModel.rangeSelections.listen(selections.add);

      viewModel.selectRange(Range.lastMonth);
      await Future<void>.delayed(Duration.zero);

      final selection = selections.single;
      expect(selection.startDate, DateTime(now.year, now.month - 1, 1));
      expect(selection.endDate, DateTime(now.year, now.month, 1));
    });
  });

  test('initData offers the ranges the screen can pick from', () {
    final viewModel = buildViewModel();

    viewModel.initData();

    // It used to raise an "initialised" flag as well, which the page read to
    // decide when to pick a range. Nothing about the list depends on the role
    // check that preceded it, so the page just makes both calls.
    expect(viewModel.state.value.ranges, hasLength(6));
  });
}
