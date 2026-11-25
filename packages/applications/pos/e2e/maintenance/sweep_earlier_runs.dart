// Cleans up after an interrupted e2e run. Started only by
// tools/e2e/sweep.sh <local|hosted>; run-all.sh never picks it up (it is
// not a *_test.dart file at e2e/'s top level).
//
// Signed in as admin, through the app's own repositories, it touches only
// data the suite names:
// - every bill of the last 3 days whose every line is a suite product
//   (named `E2E-…`): cancelled; a bill that mixes a suite product with
//   anything else is left and reported;
// - every product not yet deleted whose name starts with `E2E-`: its stock
//   is zeroed and it is deleted;
// - customers named `E2E-<run id> …`: removed (archived) on the local
//   target; the hosted target keeps every customer, the kept `E2E customer`
//   included;
// - draft receipts whose reference starts with a run id
//   (`yyyyMMddHHmmss-<pid>`, as the suite writes them): cancelled.
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
import '../support/stock_plan.dart';

const _suitePrefix = 'E2E-';
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
        if (p.name.startsWith(_suitePrefix)) p,
    ];

Future<void> _sweepProduct(Product product) async {
  final zeroed = await zeroStockOf(product);
  await getIt()<ProductRepository>().removeProductById(product.id);
  _did.add('product "${product.name}": $zeroed lot(s) zeroed, deleted');
}

/// Bills of the last [_billLookBack]: one whose every line is a suite
/// product (named `E2E-…`, deleted or not) is cancelled; one that mixes a
/// suite product with anything else is left and reported (the rule of
/// [sweepDecision], over all suite products).
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
    final suite = names.where((n) => n.startsWith(_suitePrefix)).toList();
    if (suite.isEmpty) continue;
    if (suite.length != names.length) {
      _left.add('bill ${bill.code}: holds a suite product with other items '
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
    if (!customer.name.startsWith(_suitePrefix)) continue;
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
