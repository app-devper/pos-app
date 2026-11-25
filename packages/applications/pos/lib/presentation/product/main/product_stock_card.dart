// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/date_ext.dart';
import 'package:common/core/ext/number_ext.dart';
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/spacing.dart';

// Project imports:
import 'package:pos/domain/model/product/product.dart';

/// One unit's card on the product's stock tab: the total on hand, then a
/// column per figure with one row per lot (its number included), and the
/// actions on each lot.
class ProductStockCard extends StatelessWidget {
  final ProductUnit unit;
  final List<ProductStock> stocks;

  /// The unit's General price, shown where a lot has no price of its own.
  final ProductPrice price;
  final VoidCallback onSequence;
  final VoidCallback onAdd;
  final ValueChanged<ProductStock> onEdit;
  final ValueChanged<ProductStock> onQuantity;
  final ValueChanged<ProductStock> onAdjust;

  const ProductStockCard({
    super.key,
    required this.unit,
    required this.stocks,
    required this.price,
    required this.onSequence,
    required this.onAdd,
    required this.onEdit,
    required this.onQuantity,
    required this.onAdjust,
  });

  static const _figure = TextStyle(fontSize: 16.0);
  static const _boldFigure =
      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    final total = stocks.fold(0, (sum, stock) => sum + stock.quantity);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 4.0),
            Text(
              'คงเหลือรวมทั้งหมด: $total ${unit.unit}',
              style: TextStyle(
                fontSize: 16.0,
                color: AppColors.of(context).textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildTable(context),
          ],
        ),
      ),
    );
  }

  /// The columns spread over the card's width; where they need more (a
  /// phone, a long lot number) the table scrolls sideways, so every figure
  /// stays whole and each lot stays on one line across the columns.
  Widget _buildTable(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _spaced(_buildColumns(context)),
          ),
        ),
      ),
    );
  }

  /// [columns] with a gap between each, so they never touch when scrolled.
  static List<Widget> _spaced(List<Widget> columns) => [
        for (final (index, column) in columns.indexed) ...[
          if (index > 0) const SizedBox(width: _columnGap),
          column,
        ],
      ];

  static const _columnGap = 16.0;

  Widget _buildHeader(BuildContext context) {
    return Row(children: [
      Text(
        unit.unit,
        style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
      ),
      const Spacer(),
      _action(context, 'จัดเรียงสต็อก', onSequence),
      _action(context, 'เพิ่มสต็อก', onAdd),
    ]);
  }

  Widget _action(BuildContext context, String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildColumns(BuildContext context) {
    return [
      _column(context, 'นำเข้าเมื่อ', CrossAxisAlignment.start,
          (stock) => _importDate(context, stock)),
      _column(context, 'ล็อต', CrossAxisAlignment.start,
          (stock) => Text(stock.lotNumber, style: _figure)),
      _column(context, 'วันหมดอายุ', CrossAxisAlignment.center,
          (stock) => Text(stock.expireDate.formatShortDate(), style: _figure)),
      _column(context, 'ต้นทุน', CrossAxisAlignment.end,
          (stock) => _amount(context, stock.costPrice, unit.costPrice)),
      _column(context, 'ราคาขาย', CrossAxisAlignment.end,
          (stock) => _amount(context, stock.price, price.price)),
      _column(context, 'นำเข้า', CrossAxisAlignment.center,
          (stock) => Text('${stock.import}x', style: _boldFigure)),
      _column(context, 'คงเหลือ', CrossAxisAlignment.center,
          (stock) => _onHand(stock)),
      _adjustColumn(),
    ];
  }

  Widget _column(BuildContext context, String label,
      CrossAxisAlignment alignment, Widget Function(ProductStock) row) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: AppColors.of(context).textSecondary,
          ),
        ),
        const SizedBox(height: 4.0),
        ...stocks.map(row),
      ],
    );
  }

  Widget _importDate(BuildContext context, ProductStock stock) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(stock.importDate.formatShortDate(), style: _figure),
        const SizedBox(width: 4.0),
        InkWell(
          onTap: () => onEdit(stock),
          child: Text(
            'แก้ไข',
            style: TextStyle(
              fontSize: 14.0,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }

  /// The lot's own amount, or the unit's (greyed) when the lot has none.
  Widget _amount(BuildContext context, double own, double fallback) {
    if (own > 0) return Text('฿${formatDouble(own)}', style: _boldFigure);
    return Text(
      '฿${formatDouble(fallback)}',
      style: TextStyle(
        fontSize: 16.0,
        color: AppColors.of(context).textSecondary,
      ),
    );
  }

  Widget _onHand(ProductStock stock) {
    return InkWell(
      onTap: () => onQuantity(stock),
      child: Text(
        '${stock.quantity}x',
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _adjustColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 22.0),
        ...stocks.map(
          (stock) => SizedBox(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            child: IconButton(
              padding: EdgeInsets.zero,
              splashRadius: 16,
              icon: const Icon(Icons.tune, size: 18),
              tooltip: 'ปรับสต็อก',
              onPressed: () => onAdjust(stock),
            ),
          ),
        ),
      ],
    );
  }
}
