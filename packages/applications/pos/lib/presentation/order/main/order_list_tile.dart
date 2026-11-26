// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/text_styles.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_summary.dart';
import 'package:pos/presentation/order/bill_summary.dart';
import 'package:pos/presentation/order/cancelled_mark.dart';

/// The smallest a row's muted labels are drawn (its position).
const _minLabelSize = 12.0;

/// One bill in the bills list: its position as a muted label, its bill
/// number above its time (and customer), its total at the end as the row's
/// most prominent text, and for an admin its cost and profit. The
/// number is visible text, so a cashier, assistive technology and a UI test
/// all tell one bill from another by it. A cancelled bill is still listed,
/// marked [cancelledLabel], its amount struck through.
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
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodySmall
        ?.copyWith(color: AppColors.of(context).textSecondary);
    final time = order.getCreatedDate() +
        (order.customerName.isNotEmpty ? " Name: ${order.customerName}" : "");
    return ListTile(
      leading: Text("${index + 1}",
          style: secondary?.copyWith(fontSize: _minLabelSize)),
      minLeadingWidth: 24,
      title: Text(order.code,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (order.isCancelled) const CancelledBadge(),
          Text(time, style: secondary),
          if (showCost)
            Text(
                costAndProfitText(
                    cost: order.totalCost,
                    profit: order.total - order.totalCost),
                style: secondary),
        ],
      ),
      trailing:
          Text('฿${_format.format(order.total)}', style: _amountStyle(theme)),
      onTap: onTap,
    );
  }

  /// The row's most prominent text: bold, its figures in even columns.
  TextStyle? _amountStyle(ThemeData theme) =>
      AppText.money(theme.textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold)
          .merge(amountStyle(cancelled: order.isCancelled)));
}
