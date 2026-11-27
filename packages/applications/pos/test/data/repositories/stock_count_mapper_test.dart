// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/data/repositories/stock_count_mapper.dart';

Map<String, dynamic> _line(Map<String, dynamic> extra) => {
      'productId': 'p1',
      'stockId': 's1',
      'systemQuantity': 10,
      'countedQuantity': 8,
      'delta': -2,
      ...extra,
    };

void main() {
  test('a counted line carries the names pos-api resolved', () {
    // Act
    final item = _line({
      'productName': 'Paracetamol',
      'unit': 'กล่อง',
      'lotNumber': 'L1',
    }).toStockCountItemDomain();

    // Assert
    expect(item.productName, 'Paracetamol');
    expect(item.unit, 'กล่อง');
    expect(item.lotNumber, 'L1');
  });

  test('a line from a pos-api without the names has them empty', () {
    // Act
    final item = _line(const {}).toStockCountItemDomain();

    // Assert
    expect(item.productName, '');
    expect(item.unit, '');
    expect(item.lotNumber, '');
    expect(item.delta, -2);
  });
}
