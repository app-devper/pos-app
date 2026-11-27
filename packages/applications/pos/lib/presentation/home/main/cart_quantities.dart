// Project imports:
import 'package:pos/domain/model/order/order_item.dart';

/// How many of each product [lines] hold, by the unit's barcode: what the
/// selling grid shows on a card as "ในตะกร้า n". Lines of the same unit (two
/// lots, two prices) are added together.
Map<String, int> cartQuantities(List<OrderItem> lines) {
  final quantities = <String, int>{};
  for (final line in lines) {
    final barcode = line.product.unit.barcode;
    quantities[barcode] = (quantities[barcode] ?? 0) + line.quantity;
  }
  return Map.unmodifiable(quantities);
}
