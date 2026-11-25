// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/sale/money.dart';
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

  const OrderDetailState({
    this.loading = false,
    this.order,
    this.isAdmin = false,
  });

  /// The lines to list. An order that has not arrived yet has none, which is
  /// what the list renders before the first load finishes.
  List<OrderItemDetail> get items => order?.items ?? const [];

  /// The lines that count: a cancelled line is listed but counts in no
  /// total.
  Iterable<OrderItemDetail> get _counted =>
      items.where((line) => !line.isCancelled);

  /// What the customer paid for the bill: the sum of its counted lines.
  double get total => saleTotal(_counted.map((x) => x.paid()));

  /// What the bill's counted lines cost.
  double get totalCost =>
      roundMoney(_counted.fold(0.0, (sum, x) => sum + x.costPrice));

  OrderDetailState copyWith({
    bool? loading,
    OrderDetail? order,
    bool? isAdmin,
  }) {
    return OrderDetailState(
      loading: loading ?? this.loading,
      order: order ?? this.order,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
