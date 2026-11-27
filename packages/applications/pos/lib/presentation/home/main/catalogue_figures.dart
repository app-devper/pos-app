// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'package:pos/domain/model/product/product.dart';

/// The selling screen's three figures about the catalogue on sale.
@immutable
class CatalogueFigures {
  /// How many products are on sale.
  final int products;

  /// What is on hand over all of them; an oversold unit counts as none.
  final int totalStock;

  /// How many products have a unit at or under the level the shop set.
  final int lowStock;

  const CatalogueFigures({
    required this.products,
    required this.totalStock,
    required this.lowStock,
  });

  static const empty = CatalogueFigures(products: 0, totalStock: 0, lowStock: 0);

  /// The figures of [items], the unit items the grid holds: a product of
  /// several units is counted once.
  factory CatalogueFigures.of(List<ProductUnitItem> items) {
    final products = <String>{};
    final low = <String>{};
    var stock = 0;
    for (final item in items) {
      final quantity = item.getQuantity();
      products.add(item.id);
      if (quantity > 0) stock += quantity;
      if (item.isLowStock) low.add(item.id);
    }
    return CatalogueFigures(
      products: products.length,
      totalStock: stock,
      lowStock: low.length,
    );
  }
}
