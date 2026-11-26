// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';

// Project imports:
import 'package:pos/domain/model/stock_count/stock_count.dart';

/// One counted line of a stock count's detail: the product, what the system
/// held and what was counted, and the difference.
class StockCountDetailLine extends StatelessWidget {
  final StockCountItem item;
  final String? productName;

  const StockCountDetailLine({
    super.key,
    required this.item,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    final delta = item.delta;
    return ListTile(
      // A product that cannot be named (offline, or deleted since) is still
      // told apart by its id.
      title: Text(productName ?? 'สินค้า ${item.productId}'),
      subtitle: Text(
          'ในระบบ ${item.systemQuantity} / นับได้ ${item.countedQuantity}'),
      trailing: Text(
        delta == 0 ? 'ตรงกัน' : (delta > 0 ? '+$delta' : '$delta'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: delta == 0
              ? AppColors.of(context).textSecondary
              : (delta > 0 ? Colors.green : Colors.red),
        ),
      ),
    );
  }
}
