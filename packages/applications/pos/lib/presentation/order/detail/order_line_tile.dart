// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/widgets/status_badge.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/presentation/order/bill_summary.dart';
import 'package:pos/presentation/order/cancelled_mark.dart';
import 'package:pos/localizations/language/languages.dart';

/// One line of a bill: its product, quantity (with its oversold and
/// returned marks), what was paid, and for an admin its cost and profit and
/// the delete, history and return actions. A cancelled line is still
/// shown, marked [cancelledLabel], its amount struck through, and offers
/// no action.
class OrderLineTile extends StatelessWidget {
  final OrderItemDetail line;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onHistory;
  final VoidCallback onReturn;

  const OrderLineTile({
    super.key,
    required this.line,
    required this.isAdmin,
    required this.onTap,
    required this.onDelete,
    required this.onHistory,
    required this.onReturn,
  });

  static final _format = NumberFormat("#,##0.00", "en_US");

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildListMenu(context),
      title: Text(line.product?.name ?? ""),
      trailing: Text(_format.format(line.paid()),
          style: amountStyle(cancelled: line.isCancelled)),
      subtitle: _buildSubtitle(),
      onTap: onTap,
    );
  }

  /// The cancelled mark sits here, not by the quantity, so that a line
  /// with its oversold or returned marks still fits its row.
  Widget? _buildSubtitle() {
    if (!isAdmin && !line.isCancelled) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (line.isCancelled) const CancelledBadge(),
        if (isAdmin)
          Text(costAndProfitText(
              cost: line.costPrice, profit: line.paid() - line.costPrice)),
      ],
    );
  }

  Widget _buildListMenu(BuildContext context) {
    if (!isAdmin || line.isCancelled) return _buildQuantityColumn(context);
    final names = Languages.of(context);
    final product = line.product?.name ?? '';
    return SizedBox(
      width: 130,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _action(Icons.delete, names.deleteBillLine(product), onDelete),
          _action(Icons.history, names.billLineHistory(product), onHistory),
          if (line.quantity - line.returnedQty > 0)
            _action(
                Icons.keyboard_return, names.returnBillLine(product), onReturn),
          _buildQuantityColumn(context),
        ],
      ),
    );
  }

  /// An admin's icon action on the line, named for a screen reader.
  Widget _action(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Icon(icon, semanticLabel: label),
      );

  Widget _buildQuantityColumn(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text('${line.quantity}'),
        if (line.oversoldQty > 0)
          StatusBadge(label: 'เกิน ${line.oversoldQty}', color: Colors.orange),
        if (line.returnedQty > 0)
          StatusBadge(
              label: 'คืน ${line.returnedQty}',
              color: AppColors.of(context).textSecondary),
      ],
    );
  }
}
