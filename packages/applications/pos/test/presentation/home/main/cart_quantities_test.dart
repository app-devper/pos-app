import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/order/order_item.dart';
import 'package:pos/presentation/home/main/cart_quantities.dart';

import '../../../support/selling_products.dart';

OrderItem _line(String id, int quantity) =>
    OrderItem(
      product: sellingProduct(id).toProductItems().single,
      quantity: quantity,
      customerType: priceTypeStock,
    );

void main() {
  test('an empty cart holds nothing', () {
    expect(cartQuantities(const []), isEmpty);
  });

  test('adds up the lines of the same unit, by barcode', () {
    final quantities =
        cartQuantities([_line('a', 2), _line('b', 1), _line('a', 3)]);

    expect(quantities, {'bar-a': 5, 'bar-b': 1});
  });

  test('the result cannot be changed', () {
    final quantities = cartQuantities([_line('a', 1)]);

    expect(() => quantities['bar-a'] = 9, throwsUnsupportedError);
  });
}
