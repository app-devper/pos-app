// Cleans up after an interrupted e2e run. Started only by
// tools/e2e/sweep.sh <local|hosted>; run-all.sh never picks it up (it is
// not a *_test.dart file at e2e/'s top level).
//
// Run it only when no run is in progress, on any machine: it cancels a
// running file's bills and deletes its product.
//
// Signed in as admin, through the app's own repositories, it acts on these
// names only. A run name is `E2E-<yyyyMMddHHmmss>-<pid> <what>`
// (RunData.runNamePattern), so the kept `E2E customer` and `E2E supplier`,
// and any other name merely starting `E2E-`, are never touched:
// - every bill of the last 3 days whose every line is a run-named product
//   is cancelled, whoever rang it up (a cashier may have sold the run's
//   product from the selling grid); a bill that mixes one with anything else
//   is left and reported;
// - every run-named product not yet deleted: its lots are zeroed, its stock
//   rows deleted, then it is deleted (support/api/product_api.dart
//   retireProduct);
// - run-named customers: removed (archived) on the local target; the
//   hosted target keeps every customer;
// - draft receipts whose reference starts with a run id followed by a
//   space, a hyphen or nothing (`^\d{14}-\d+([ -]|$)`, as the suite
//   writes references): cancelled. A receipt reference is free text, so a
//   real one typed in that shape would match too.
// It prints what it did and what it left.

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:common/core/error/exception.dart';
import 'package:common/injection.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/order/param.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/model/receive/param.dart';
import 'package:pos/domain/repositories/customer_repository.dart';
import 'package:pos/domain/repositories/order_repository.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/domain/repositories/receive_repository.dart';
import '../support/api/product_api.dart';
import '../support/app.dart';
import '../support/customer_plan.dart';
import '../support/env.dart';
import '../support/run_data.dart';
import '../support/stock_plan.dart';

final _runReference = RegExp(r'^\d{14}-\d+([ -]|$)');
const _alreadyCancelled = 'บิลนี้ถูกยกเลิกไปแล้ว';
const _receiptLookBack = Duration(days: 30);

/// An interrupted run is noticed within days; a longer look-back reads
/// every bill of a busy shop one by one.
const _billLookBack = Duration(days: 3);

final _did = <String>[];
final _left = <String>[];

void main() {
  initE2E();

  testWidgets('sweep what earlier runs left', (tester) async {
    await launchApp(tester);
    await signIn(tester);

    // Bills first: cancelling one puts its stock back, which the product
    // pass then zeroes.
    await _sweepBills();
    for (final product in await _suiteProducts()) {
      await _sweepProduct(product);
    }
    await _sweepCustomers();
    await _sweepDraftReceipts();

    debugPrint('E2E sweep did: ${_did.isEmpty ? 'nothing' : ''}');
    for (final line in _did) {
      debugPrint('  - $line');
    }
    debugPrint('E2E sweep left: ${_left.isEmpty ? 'nothing' : ''}');
    for (final line in _left) {
      debugPrint('  - $line');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}

Future<List<Product>> _suiteProducts() async => [
      for (final p in await getIt()<ProductRepository>().getProducts())
        if (RunData.runNamePattern.hasMatch(p.name)) p,
    ];

Future<void> _sweepProduct(Product product) async {
  final r = await retireProduct(product);
  _did.add('product "${product.name}": ${r.zeroed} lot(s) zeroed, '
      '${r.rowsDeleted} stock row(s) deleted, product deleted');
  for (final row in r.rowsKept) {
    _left.add('$row of "${product.name}" NOT deleted');
  }
}

/// Bills of the last [_billLookBack]: one whose every line is a run-named
/// product (deleted or not) is cancelled, whoever rang it up; one that mixes
/// a run-named product with anything else is left and reported (the rule
/// of [sweepDecision], over all run-named products).
Future<void> _sweepBills() async {
  final orders = getIt()<OrderRepository>();
  final now = DateTime.now();
  final summaries = await orders.getOrderRange(GetOrderRangeParam(
    startDate: now.subtract(_billLookBack).toUtc().toIso8601String(),
    endDate: now.add(const Duration(days: 1)).toUtc().toIso8601String(),
  ));
  for (final summary in summaries) {
    final bill = await orders.getOrderById(summary.id);
    final names = [for (final item in bill.items) item.product?.name ?? ''];
    final suite = names.where(RunData.runNamePattern.hasMatch).toList();
    if (suite.isEmpty) continue;
    if (suite.length != names.length) {
      _left.add('bill ${bill.code}: holds a run-named product with other items '
          '— NOT cancelled, it was not made by the suite');
      continue;
    }
    try {
      await orders.removeOrderById(bill.id);
      _did.add('bill ${bill.code} (${names.toSet().join(', ')}) cancelled');
    } on AppException catch (e) {
      if (!e.message.contains(_alreadyCancelled)) rethrow;
    }
  }
}

Future<void> _sweepCustomers() async {
  final repository = getIt()<CustomerRepository>();
  for (final customer in await repository.getCustomers()) {
    if (!RunData.runNamePattern.hasMatch(customer.name)) continue;
    if (customer.status == archivedStatus) continue;
    if (E2EEnv.isHosted) {
      _left.add('customer "${customer.name}" (hosted: customers are kept)');
      continue;
    }
    await repository.removeCustomerById(customer.id);
    _did.add('customer "${customer.name}" removed (archived)');
  }
}

Future<void> _sweepDraftReceipts() async {
  final repository = getIt()<ReceiveRepository>();
  final now = DateTime.now();
  final receives = await repository.getReceives(GetReceivesRangeParam(
    startDate: now.subtract(_receiptLookBack).toUtc().toIso8601String(),
    endDate: now.add(const Duration(days: 1)).toUtc().toIso8601String(),
  ));
  for (final receive in receives) {
    if (!_runReference.hasMatch(receive.reference)) continue;
    if (receive.isImported || receive.status == cancelledReceiveStatus) {
      continue;
    }
    await repository.removeReceiveById(receive.id);
    _did.add('draft receipt ${receive.code} "${receive.reference}" cancelled');
  }
}
