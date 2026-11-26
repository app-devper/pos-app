// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/text_styles.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/sale/money.dart';
import 'package:pos/presentation/constants.dart';

final _money = NumberFormat("#,##0.00", "en_US");

/// A line's or a bill's cost and profit, as an admin reads them.
String costAndProfitText({required double cost, required double profit}) =>
    'ต้นทุน: ${_money.format(cost)}  กำไร: ${_money.format(profit)}';

/// The foot of the bills list and of a bill, a raised surface under a top
/// border: its total, emphasised, and for an admin its cost and profit.
class BillSummary extends StatelessWidget {
  final double total;
  final double totalCost;
  final bool showCost;

  const BillSummary({
    super.key,
    required this.total,
    required this.totalCost,
    required this.showCost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final emphasised =
        theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceRaised,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      // The surface reaches the screen's edge; its rows keep clear of the
      // bottom inset (a phone's gesture bar) when it is a page's bottom bar.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(defaultPagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _row('ยอดรวม', total, emphasised),
              if (showCost) ...[
                _row('ต้นทุน', totalCost, body),
                _row('กำไร', roundMoney(total - totalCost), body),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// A row of the foot, read as one node of its own (`ยอดรวม ฿ 75.00`): on
  /// the web a text merged into a node with children is not written into
  /// the page.
  Widget _row(String label, double amount, TextStyle? style) {
    final figure = '฿ ${_money.format(amount)}';
    return Semantics(
      container: true,
      label: '$label $figure',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: style),
          Text(figure, style: AppText.money(style)),
        ],
      ),
    );
  }
}
