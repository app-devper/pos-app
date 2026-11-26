// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';
import 'package:design_system/theme/app_colors.dart';

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

/// A row of the สินค้า list: the product's name, and under it its price and
/// what is on hand in its first unit, as the selling grid's card shows them.
/// A product with no unit has no stock to show: its price only.
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
    final item = product.toProductItems().firstOrNull;
    if (item == null) {
      return TextSpan(text: '฿${formatDouble(product.price)}');
    }
    final price = item.getPrice(priceTypeStock).price;
    return TextSpan(children: [
      TextSpan(text: '฿${formatDouble(price)} · '),
      _stock(context, item.getQuantity(), item.unit.unit),
    ]);
  }

  TextSpan _stock(BuildContext context, int onHand, String unit) {
    final languages = Languages.of(context);
    final onHandText = languages.productOnHand('$onHand', unit);
    return switch (stockLevelOf(onHand, product.minStock)) {
      StockLevel.inStock => TextSpan(text: onHandText),
      StockLevel.low => _flagged(
          '$onHandText · ${languages.lowStock}', AppColors.of(context).warning),
      StockLevel.out => _flagged('$onHandText · ${languages.outOfStock}',
          Theme.of(context).colorScheme.error),
    };
  }

  TextSpan _flagged(String text, Color color) => TextSpan(
        text: text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      );
}
