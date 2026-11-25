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

/// What the clean-up may do with a bill that holds the run's product.
enum SweepDecision { cancel, refuse, ignore }

/// [lineProducts] are the product names of a bill's lines (null when a line
/// has none). Only a bill whose every line is [runProduct] can have been
/// made by the run, and is cancelled. One that mixes it with anything else
/// was rung up by someone else (the run's product is on the real selling
/// grid while a file runs) and is refused. Pure, so it is unit-tested.
SweepDecision sweepDecision(List<String?> lineProducts, String runProduct) {
  if (!lineProducts.contains(runProduct)) return SweepDecision.ignore;
  return lineProducts.every((name) => name == runProduct)
      ? SweepDecision.cancel
      : SweepDecision.refuse;
}

SweepDecision decisionFor(OrderDetail bill, String runProduct) => sweepDecision(
    [for (final item in bill.items) item.product?.name], runProduct);

/// Says loudly that [bill] was left alone and reports it as a leftover.
void reportMixedBill(OrderDetail bill, String runProduct) {
  debugPrint('E2E: bill ${bill.code} holds the run\'s product together with '
      'other items; NOT cancelled — it was not made by this run');
  Cleanup.keep('bill ${bill.code} holding "$runProduct" with other items '
      '(NOT cancelled: not made by this run)');
}

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

  /// The list row's line under the bill number: `dd/MM/yyyy HH:mm`, then
  /// ` Name: <customer>`.
  final String rowTitle;

  /// The detail's header: `<code> dd/MM/yyyy HH:mm`.
  final String header;

  /// The list row's trailing total, `#,##0.00`, as recorded.
  final String totalText;
}

/// The ids of the bills in the file's window (see [billWindow]), as the
/// server has them now.
Future<Set<String>> fileOrderIds() async =>
    {for (final order in await _fileOrders()) order.id};

/// [id] as the server has it now (its total changes when a line is
/// cancelled).
Future<Bill> billNow(String id) async =>
    Bill.of(await getIt()<OrderRepository>().getOrderById(id));

/// The bills recorded since [before] was taken that hold [productName].
Future<List<OrderDetail>> billsOfProductSince(
    String productName, Set<String> before) async {
  final repository = getIt()<OrderRepository>();
  final bills = <OrderDetail>[];
  for (final order in await _fileOrders()) {
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

  /// Every bill a test recorded, cancelled or not.
  final _recorded = <String>{};
  Set<String>? _firstSnapshot;

  /// The window's order ids, taken before a sale; [cancelAll] also sweeps
  /// every bill of [productName] recorded since the first of these.
  Future<Set<String>> beforeSale() async {
    final ids = await fileOrderIds();
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
    final bill = bills.single;
    if (decisionFor(bill, productName) != SweepDecision.cancel) {
      reportMixedBill(bill, productName);
      throw StateError('E2E: the new bill ${bill.code} of $productName holds '
          'other items too; it is not the test\'s');
    }
    return _track(Bill.of(bill));
  }

  Bill _track(Bill bill) {
    _standing.add(bill);
    _recorded.add(bill.id);
    Cleanup.keep('order ${bill.code} (cancelled, cannot be deleted)');
    return bill;
  }

  /// [bill] was cancelled on screen.
  void markCancelled(Bill bill) => _standing.remove(bill);

  /// Cancels every bill not yet cancelled, as the detail's delete does;
  /// one cancelled meanwhile counts as done. Tries every one, whatever
  /// fails, then rethrows the first failure.
  Future<void> cancelAll() async {
    Object? firstError;
    StackTrace? firstStack;
    try {
      await _sweep();
    } on Object catch (error, stack) {
      // The recorded bills are still cancelled below.
      firstError = error;
      firstStack = stack;
    }
    final repository = getIt()<OrderRepository>();
    for (final bill in List.of(_standing)) {
      try {
        await repository.removeOrderById(bill.id);
      } on Object catch (error, stack) {
        if (!_isAlreadyCancelled(error)) {
          firstError ??= error;
          firstStack ??= stack;
          continue;
        }
      }
      _standing.remove(bill);
    }
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }

  static bool _isAlreadyCancelled(Object error) =>
      error is AppException && error.message.contains(_alreadyCancelled);

  /// Tracks every bill of [productName] since the first snapshot that no
  /// test recorded (a step failed between paying and recording it), if its
  /// every line is [productName]; a bill that mixes in other items is left
  /// alone and reported (see [sweepDecision]).
  Future<void> _sweep() async {
    final first = _firstSnapshot;
    if (first == null) return;
    for (final detail in await billsOfProductSince(productName, first)) {
      if (_recorded.contains(detail.id)) continue;
      if (decisionFor(detail, productName) != SweepDecision.cancel) {
        reportMixedBill(detail, productName);
        continue;
      }
      debugPrint('E2E: bill ${detail.code} of $productName was never '
          'recorded by a test; cancelling it at clean-up');
      _track(Bill.of(detail));
    }
  }
}

/// When the file first looked for bills; the window starts that day.
DateTime? _firstLook;

/// The range a file's bill look-ups ask for: from the local midnight that
/// began the day of [firstLook] to a day after [now]. A bill paid just
/// before midnight is still found, and cancelled, just after it.
({DateTime start, DateTime end}) billWindow(DateTime firstLook, DateTime now) =>
    (
      start: DateTime(firstLook.year, firstLook.month, firstLook.day),
      end: now.add(const Duration(days: 1)),
    );

Future<List<OrderSummary>> _fileOrders() {
  final now = DateTime.now();
  final window = billWindow(_firstLook ??= now, now);
  return getIt()<OrderRepository>().getOrderRange(GetOrderRangeParam(
    startDate: window.start.toUtc().toIso8601String(),
    endDate: window.end.toUtc().toIso8601String(),
  ));
}
