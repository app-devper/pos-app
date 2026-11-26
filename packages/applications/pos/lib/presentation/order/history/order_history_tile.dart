// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/presentation/order/bill_summary.dart';
import 'package:pos/presentation/order/cancelled_mark.dart';

/// One line of a product's sales history: quantity, date and customer,
/// what was paid, and for an admin its cost and profit. A cancelled line is
/// still shown, marked [cancelledLabel], its amount struck through, as on
/// the bill.
class OrderHistoryTile extends StatelessWidget {
  final OrderItemDetail line;
  final bool showCost;

  const OrderHistoryTile({
    super.key,
    required this.line,
    required this.showCost,
  });

  static final _format = NumberFormat("#,##0.00", "en_US");

  @override
  Widget build(BuildContext context) {
    final customerName = line.order?.customerName ?? "";
    return ListTile(
      leading: Text('${line.quantity}'),
      title: Text(line.getCreatedDate() +
          (customerName.isNotEmpty ? " ลูกค้า: $customerName" : "")),
      trailing: Text(_format.format(line.paid()),
          style: amountStyle(cancelled: line.isCancelled)),
      subtitle: _buildSubtitle(),
    );
  }

  Widget? _buildSubtitle() {
    if (!showCost && !line.isCancelled) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (line.isCancelled) const CancelledBadge(),
        if (showCost)
          Text(costAndProfitText(
              cost: line.costPrice, profit: line.paid() - line.costPrice)),
      ],
    );
  }
}
