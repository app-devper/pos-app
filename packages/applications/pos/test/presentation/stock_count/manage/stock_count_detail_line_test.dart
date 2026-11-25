// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/stock_count/stock_count.dart';
import 'package:pos/presentation/stock_count/manage/stock_count_detail_line.dart';

final _line = StockCountItem(
    productId: '6650aa',
    stockId: 's1',
    systemQuantity: 10,
    countedQuantity: 8,
    delta: -2);

Widget _host(String? name) => MaterialApp(
    home: Scaffold(body: StockCountDetailLine(item: _line, productName: name)));

void main() {
  testWidgets('a counted line is titled with its product\'s name',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host('Paracetamol'));

    // Assert
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.textContaining('6650aa'), findsNothing);
    expect(find.text('ในระบบ 10 / นับได้ 8'), findsOneWidget);
    expect(find.text('-2'), findsOneWidget);
  });

  testWidgets('a line whose product is unknown falls back to its id',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(null));

    // Assert
    expect(find.text('สินค้า 6650aa'), findsOneWidget);
  });
}
