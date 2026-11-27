// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';

// Project imports:
import 'package:pos/domain/model/stock_count/stock_count.dart';

/// One counted line of a stock count's detail: the product, what the system
/// held and what was counted (in its unit, of its lot), and the difference.
///
/// The product is named as pos-api named the line; failing that by
/// [productName], the catalogue's name for it.
class StockCountDetailLine extends StatelessWidget {
  final StockCountItem item;
  final String? productName;

  /// A product that cannot be named at all is still told apart by its id.
  String get _title {
    if (item.productName.isNotEmpty) return item.productName;
    return productName ?? 'สินค้า ${item.productId}';
  }

  String get _quantities {
    final counted = [
      'ในระบบ ${item.systemQuantity} / นับได้ ${item.countedQuantity}',
      if (item.unit.isNotEmpty) item.unit,
    ].join(' ');
    if (item.lotNumber.isEmpty) return counted;
    return '$counted · ล็อต ${item.lotNumber}';
  }

  const StockCountDetailLine({
    super.key,
    required this.item,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    final delta = item.delta;
    return ListTile(
      title: Text(_title),
      subtitle: Text(_quantities),
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
