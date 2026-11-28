// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/text_styles.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_summary.dart';
import 'package:pos/localizations/language/languages.dart';
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

  /// From this width a row reads across, its parts in columns.
  static const double _wideFrom = 720;
  static const double _indexWidth = 40;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= _wideFrom
          ? _buildWide(context)
          : _buildNarrow(context),
    );
  }

  /// A cancelled bill is still listed, but its text is muted.
  Color? _textColor(BuildContext context) =>
      order.isCancelled ? AppColors.of(context).textSecondary : null;

  TextStyle? _secondary(BuildContext context) => Theme.of(context)
      .textTheme
      .bodySmall
      ?.copyWith(color: AppColors.of(context).textSecondary);

  String _time(BuildContext context) {
    final customer = order.customerName;
    return order.getCreatedDate() +
        (customer.isNotEmpty
            ? " ${Languages.of(context).customerNamed(customer)}"
            : "");
  }

  String get _costText => costAndProfitText(
      cost: order.totalCost, profit: order.total - order.totalCost);

  Text _index(BuildContext context) => Text("${index + 1}",
      style: _secondary(context)?.copyWith(fontSize: _minLabelSize));

  Text _code(BuildContext context) => Text(order.code,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold, color: _textColor(context)));

  Text _amount(BuildContext context) =>
      Text('฿${_format.format(order.total)}', style: _amountStyle(context));

  Widget _buildNarrow(BuildContext context) {
    final secondary = _secondary(context);
    return ListTile(
      leading: _index(context),
      minLeadingWidth: 24,
      title: _code(context),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (order.isCancelled) const CancelledBadge(),
          Text(_time(context), style: secondary),
          if (showCost) Text(_costText, style: secondary),
        ],
      ),
      trailing: _amount(context),
      onTap: onTap,
    );
  }

  /// A wide list's row: number, bill number (and its mark), time and
  /// customer, cost and profit for an admin, then the amount at the end.
  /// Read as one node, in that order, as the phone's row is.
  Widget _buildWide(BuildContext context) {
    final secondary = _secondary(context);
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(width: _indexWidth, child: _index(context)),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Flexible(child: _code(context)),
                      if (order.isCancelled) ...[
                        const SizedBox(width: 8),
                        const CancelledBadge(),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(_time(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondary),
                ),
                if (showCost)
                  Expanded(
                    flex: 3,
                    child: Text(_costText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: secondary),
                  ),
                const SizedBox(width: 16),
                _amount(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The row's most prominent text: bold, its figures in even columns.
  TextStyle? _amountStyle(BuildContext context) =>
      AppText.money(Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold, color: _textColor(context))
          .merge(amountStyle(cancelled: order.isCancelled)));
}
