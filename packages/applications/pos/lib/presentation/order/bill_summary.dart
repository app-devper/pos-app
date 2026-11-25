// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/sale/money.dart';
import 'package:pos/presentation/constants.dart';

final _money = NumberFormat("#,##0.00", "en_US");

/// A line's or a bill's cost and profit, as an admin reads them.
String costAndProfitText({required double cost, required double profit}) =>
    'ต้นทุน: ${_money.format(cost)}  กำไร: ${_money.format(profit)}';

/// The foot of the bills list and of a bill: its total, and for an admin its
/// cost and profit.
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
    return Container(
      padding: const EdgeInsets.all(defaultPagePadding),
      child: Column(
        children: <Widget>[
          _row('ยอดรวม', total),
          if (showCost) ...[
            _row('ต้นทุน', totalCost),
            _row('กำไร', roundMoney(total - totalCost)),
          ],
        ],
      ),
    );
  }

  Row _row(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label),
        Text('฿ ${_money.format(amount)}'),
      ],
    );
  }
}
