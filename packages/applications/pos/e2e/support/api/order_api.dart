// Bill look-ups and clean-up through the app's own order repository. A bill
// list row shows only its time, total and customer, so a test finds the bill
// it just recorded here (the new bill holding the run's product), then looks
// for that row and checks the detail's code.

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:common/core/error/exception.dart';
import 'package:common/injection.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/order/order_summary.dart';
import 'package:pos/domain/model/order/param.dart';
import 'package:pos/domain/repositories/order_repository.dart';
import '../cleanup.dart';

/// pos-api's refusal to cancel a bill twice (ledger/cancel.go:34).
const _alreadyCancelled = 'บิลนี้ถูกยกเลิกไปแล้ว';

final _money = NumberFormat('#,##0.00', 'en_US');

/// A bill as the bill list and its detail show it.
class Bill {
  Bill.of(OrderDetail detail)
      : id = detail.id,
        code = detail.code,
        rowTitle = detail.getCreatedDate() +
            (detail.customerName.isNotEmpty
                ? ' Name: ${detail.customerName}'
                : ''),
        header = '${detail.code} ${detail.getCreatedDate()}',
        totalText = _money.format(detail.total);

  final String id;
  final String code;

  /// The list row's title: `dd/MM/yyyy HH:mm`, then ` Name: <customer>`.
  final String rowTitle;

  /// The detail's header: `<code> dd/MM/yyyy HH:mm`.
  final String header;

  /// The list row's trailing total, `#,##0.00`, as recorded.
  final String totalText;
}

/// The ids of today's bills, as the bill list asks for them (local
/// midnight to midnight).
Future<Set<String>> todaysOrderIds() async =>
    {for (final order in await _todaysOrders()) order.id};

/// [id] as the server has it now (its total changes when a line is
/// cancelled).
Future<Bill> billNow(String id) async =>
    Bill.of(await getIt()<OrderRepository>().getOrderById(id));

/// The bills recorded since [before] was taken that hold [productName].
Future<List<OrderDetail>> billsOfProductSince(
    String productName, Set<String> before) async {
  final repository = getIt()<OrderRepository>();
  final bills = <OrderDetail>[];
  for (final order in await _todaysOrders()) {
    if (before.contains(order.id)) continue;
    final detail = await repository.getOrderById(order.id);
    if (detail.items.any((item) => item.product?.name == productName)) {
      bills.add(detail);
    }
  }
  return bills;
}

/// The bills a file records for its own product, so that every one is
/// cancelled by the end, including one a failed step paid for but never
/// recorded.
class BillLedger {
  BillLedger(this.productName);

  /// The run's own product: a bill holding it is the file's.
  final String productName;

  final _standing = <Bill>[];
  Set<String>? _firstSnapshot;

  /// Today's order ids, taken before a sale; [cancelAll] also sweeps every
  /// bill of [productName] recorded since the first of these.
  Future<Set<String>> beforeSale() async {
    final ids = await todaysOrderIds();
    _firstSnapshot ??= ids;
    return ids;
  }

  /// The one bill of [productName] recorded since [before]; it is reported
  /// as kept (a bill can be cancelled, never deleted) and is cancelled by
  /// [cancelAll] unless a test cancels it first.
  Future<Bill> recordNew(Set<String> before) async {
    final bills = await billsOfProductSince(productName, before);
    if (bills.length != 1) {
      throw StateError('E2E: expected one new bill of $productName, '
          'found ${bills.length}');
    }
    return _track(Bill.of(bills.single));
  }

  Bill _track(Bill bill) {
    _standing.add(bill);
    Cleanup.keep('order ${bill.code} (cancelled, cannot be deleted)');
    return bill;
  }

  /// [bill] was cancelled on screen.
  void markCancelled(Bill bill) => _standing.remove(bill);

  /// Cancels every bill not yet cancelled, as the detail's delete does;
  /// one cancelled meanwhile counts as done. Tries every one, then rethrows
  /// the first failure.
  Future<void> cancelAll() async {
    await _sweep();
    final repository = getIt()<OrderRepository>();
    Object? firstError;
    StackTrace? firstStack;
    for (final bill in List.of(_standing)) {
      try {
        await repository.removeOrderById(bill.id);
      } on AppException catch (error, stack) {
        if (!error.message.contains(_alreadyCancelled)) {
          firstError ??= error;
          firstStack ??= stack;
          continue;
        }
      }
      _standing.remove(bill);
    }
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }

  /// Tracks every bill of [productName] since the first snapshot that no
  /// test recorded (a step failed between paying and recording it). One
  /// already cancelled is tracked too; cancelling it again counts as done.
  Future<void> _sweep() async {
    final first = _firstSnapshot;
    if (first == null) return;
    final tracked = {for (final bill in _standing) bill.id};
    for (final detail in await billsOfProductSince(productName, first)) {
      if (tracked.contains(detail.id)) continue;
      debugPrint('E2E: bill ${detail.code} of $productName found at clean-up');
      _track(Bill.of(detail));
    }
  }
}

Future<List<OrderSummary>> _todaysOrders() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day + 1);
  return getIt()<OrderRepository>().getOrderRange(GetOrderRangeParam(
    startDate: start.toUtc().toIso8601String(),
    endDate: end.toUtc().toIso8601String(),
  ));
}
