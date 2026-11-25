// Project imports:
import 'package:pos/domain/model/product/product.dart';

/// What deleting [product] asks. With stock on hand it says how much, per
/// unit, so the stock is not deleted unnoticed.
String productDeleteQuestion(Product product) {
  final onHand = [
    for (final unit in product.units)
      if (product.getQuantityByUnit(unit.id) > 0)
        '${product.getQuantityByUnit(unit.id)} ${unit.unit}',
  ];
  if (onHand.isEmpty) return 'ต้องการลบสินค้าใช่หรือไม่';
  return 'สินค้านี้มีสต็อกคงเหลือ ${onHand.join(', ')} ต้องการลบใช่หรือไม่?';
}
