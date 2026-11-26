// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/text_styles.dart';

// Project imports:
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/localizations/language/languages.dart';

/// How much of a product is left, against its minimum.
enum StockLevel { inStock, low, out }

/// [onHand] against [minStock]: none left is out; at or below a minimum the
/// shop has set is low.
StockLevel stockLevelOf(int onHand, int minStock) {
  if (onHand <= 0) return StockLevel.out;
  if (minStock > 0 && onHand <= minStock) return StockLevel.low;
  return StockLevel.inStock;
}

/// A row of the สินค้า list: the product's name, and under it its first
/// unit's price, as the selling grid's card shows it, and what is on hand in
/// each of its units (`คงเหลือ 0 ชิ้น · 20 แผง`). Whether stock is low or out
/// is the product's as a whole, the total the list sorts by. A product with
/// no unit has no stock to show: its price only.
class ProductListRow extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductListRow({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListTile(
      title: Text(product.name),
      subtitle: Text.rich(
        _summary(context),
        style: TextStyle(color: colors.textSecondary, fontSize: 14),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: colors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  TextSpan _summary(BuildContext context) {
    final items = product.toProductItems();
    if (items.isEmpty) {
      return TextSpan(
          text: '฿${formatDouble(product.price)}', style: AppText.money(null));
    }
    final price = items.first.getPrice(priceTypeStock).price;
    return TextSpan(children: [
      TextSpan(text: '฿${formatDouble(price)} · ', style: AppText.money(null)),
      TextSpan(text: _onHand(Languages.of(context), items)),
      ..._cue(context),
    ]);
  }

  /// What is on hand in each unit, the first one as `คงเหลือ <n> <unit>`.
  static String _onHand(Languages languages, List<ProductUnitItem> items) {
    final first = items.first;
    return [
      languages.productOnHand('${first.getQuantity()}', first.unit.unit),
      for (final item in items.skip(1))
        '${item.getQuantity()} ${item.unit.unit}',
    ].join(' · ');
  }

  /// หมด or ใกล้หมด after the stock, from the product's total on hand.
  List<InlineSpan> _cue(BuildContext context) {
    final languages = Languages.of(context);
    return switch (stockLevelOf(product.getQuantity(), product.minStock)) {
      StockLevel.inStock => const [],
      StockLevel.low =>
        _flagged(languages.lowStock, AppColors.of(context).warning),
      StockLevel.out =>
        _flagged(languages.outOfStock, Theme.of(context).colorScheme.error),
    };
  }

  List<InlineSpan> _flagged(String text, Color color) => [
        TextSpan(
          text: ' · $text',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ];
}
