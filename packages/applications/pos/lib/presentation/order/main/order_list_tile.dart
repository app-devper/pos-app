// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_summary.dart';
import 'package:pos/presentation/order/bill_summary.dart';

/// One bill in the bills list: its position, its bill number above its time
/// (and customer), its total, and for an admin its cost and profit. The
/// number is visible text, so a cashier, assistive technology and a UI test
/// all tell one bill from another by it.
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
    final time = order.getCreatedDate() +
        (order.customerName.isNotEmpty ? " Name: ${order.customerName}" : "");
    return ListTile(
      leading: Text("${index + 1}"),
      title: Text(order.code),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(time),
          if (showCost)
            Text(costAndProfitText(
                cost: order.totalCost, profit: order.total - order.totalCost)),
        ],
      ),
      trailing: Text(_format.format(order.total)),
      onTap: onTap,
    );
  }
}
