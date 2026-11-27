// Products for the selling screen's tests.

import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';

/// A product of one unit with [quantity] on hand, low at [minStock].
Product sellingProduct(
  String id, {
  String? name,
  String category = 'General',
  int quantity = 10,
  int minStock = 0,
  double price = 10,
  String unit = 'ชิ้น',
}) =>
    Product(
      id: id,
      name: name ?? 'สินค้า $id',
      status: productStatusActive,
      category: category,
      minStock: minStock,
      createdDate: '',
      units: [
        ProductUnit(
          id: 'unit-$id',
          productId: id,
          costPrice: 5,
          unit: unit,
          size: 1,
          barcode: 'bar-$id',
          volume: 0,
          volumeUnit: '',
        ),
      ],
      prices: const [],
      stocks: [
        ProductStock(
          id: 'stock-$id',
          unitId: 'unit-$id',
          productId: id,
          receiveCode: '',
          sequence: 1,
          lotNumber: 'LOT-$id',
          costPrice: 5,
          price: price,
          import: quantity,
          quantity: quantity,
          expireDate: '',
          importDate: '',
        ),
      ],
    );

/// The unit items of [products], as the selling grid holds them.
List<ProductUnitItem> unitItems(List<Product> products) =>
    [for (final product in products) ...product.toProductItems()];
