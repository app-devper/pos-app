// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/supplier/supplier.dart';

/// The shop's own details plus the customer to print at the top of a receipt.
@immutable
class SupplierResult {
  final Supplier supplier;
  final Customer? customer;

  const SupplierResult({
    required this.supplier,
    required this.customer,
  });
}

/// What this screen renders: the order document and whether the user is an
/// admin, plus whether a request is in flight.
///
/// It used to carry six more things — the role answer, an error, the deleted
/// order, the deleted item, a "total cost updated" flag and the supplier
/// lookup's two outcomes — each parked here and cleared by a `consume*()` the
/// page had to remember to call. None of them was ever drawn. They were an
/// error to show, a screen to pop, and a dialog to open, so they are on the
/// channel now.
@immutable
class OrderDetailState {
  final bool loading;
  final OrderDetail? order;
  final bool isAdmin;

  /// Each line's unit name by its unit id, from the product catalogue: the
  /// bill names a unit by its id only.
  final Map<String, String> unitNames;

  const OrderDetailState({
    this.loading = false,
    this.order,
    this.isAdmin = false,
    this.unitNames = const {},
  });

  /// The name of [line]'s unit, or empty while it is not known.
  String unitNameOf(OrderItemDetail line) => unitNames[line.unitId] ?? '';

  /// The lines to list. An order that has not arrived yet has none, which is
  /// what the list renders before the first load finishes.
  List<OrderItemDetail> get items => order?.items ?? const [];

  /// The lines that count (see [OrderDetail.countedLines]).
  List<OrderItemDetail> get _counted => order?.countedLines ?? const [];

  /// What the customer paid for the bill: the sum of its counted lines (a
  /// cancelled line, or any line of a cancelled bill, is listed but counts
  /// in no total).
  double get total => _counted.countedTotal;

  /// What the bill's counted lines cost.
  double get totalCost => _counted.countedCost;

  /// Whether [line] is shown as cancelled, by itself or with its bill.
  bool isLineCancelled(OrderItemDetail line) =>
      order?.isLineCancelled(line) ?? line.isCancelled;

  OrderDetailState copyWith({
    bool? loading,
    OrderDetail? order,
    bool? isAdmin,
    Map<String, String>? unitNames,
  }) {
    return OrderDetailState(
      loading: loading ?? this.loading,
      order: order ?? this.order,
      isAdmin: isAdmin ?? this.isAdmin,
      unitNames: unitNames ?? this.unitNames,
    );
  }
}
