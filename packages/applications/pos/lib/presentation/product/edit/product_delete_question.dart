// Project imports:
import 'package:pos/domain/model/product/product.dart';

/// What deleting [product] asks. With stock on hand it says how much, per
/// unit, so the stock is not deleted unnoticed — and, either way, that the
/// product's stock is set to zero in every branch, which is what pos-api
/// does (the on-hand figure is this branch's only).
String productDeleteQuestion(Product product) {
  final onHand = [
    for (final unit in product.units)
      if (product.getQuantityByUnit(unit.id) > 0)
        '${product.getQuantityByUnit(unit.id)} ${unit.unit}',
  ];
  if (onHand.isEmpty) {
    return 'สต็อกของสินค้านี้ในสาขาอื่น (ถ้ามี) จะถูกปรับเป็น 0 '
        'ต้องการลบสินค้าใช่หรือไม่?';
  }
  return 'สินค้านี้มีสต็อกคงเหลือ ${onHand.join(', ')} '
      'การลบจะปรับสต็อกของสินค้านี้เป็น 0 ในทุกสาขา ต้องการลบใช่หรือไม่?';
}
