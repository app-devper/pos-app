// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_summary.dart';

/// One bill in the bills list. The row shows its position, not its number;
/// the number is in the position's semantics label, so assistive technology
/// (and a UI test) can tell one bill from another.
class OrderListTile extends StatelessWidget {
  final int index;
  final OrderSummary order;
  final bool showCost;
  final VoidCallback onTap;

  const OrderListTile({
    super.key,
    required this.index,
    required this.order,
    required this.showCost,
    required this.onTap,
  });

  static final _format = NumberFormat("#,##0.00", "en_US");

  @override
  Widget build(BuildContext context) {
    final position = "${index + 1}";
    return ListTile(
      leading: Text(position, semanticsLabel: "$position ${order.code}"),
      title: Text(order.getCreatedDate() +
          (order.customerName.isNotEmpty
              ? " Name: ${order.customerName}"
              : "")),
      trailing: Text(_format.format(order.total)),
      subtitle: showCost
          ? Text(
              "Cost: ${_format.format(order.totalCost)}  Profit: ${_format.format(order.total - order.totalCost)}")
          : null,
      onTap: onTap,
    );
  }
}
