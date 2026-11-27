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

Widget _host(String? name, {StockCountItem? item}) => MaterialApp(
    home: Scaffold(
        body: StockCountDetailLine(item: item ?? _line, productName: name)));

StockCountItem _named({String productName = '', String lotNumber = 'L1'}) =>
    StockCountItem(
        productId: '6650aa',
        stockId: 's1',
        systemQuantity: 10,
        countedQuantity: 8,
        delta: -2,
        productName: productName,
        unit: 'กล่อง',
        lotNumber: lotNumber);

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

  testWidgets('a line is titled with the name pos-api sent, with unit and lot',
      (tester) async {
    // Arrange / Act: the catalogue no longer has the product (deleted since)
    await tester.pumpWidget(_host(null, item: _named(productName: 'Aspirin')));

    // Assert
    expect(find.text('Aspirin'), findsOneWidget);
    expect(find.text('ในระบบ 10 / นับได้ 8 กล่อง · ล็อต L1'), findsOneWidget);
  });

  testWidgets('a line without a lot shows the unit alone', (tester) async {
    // Arrange / Act
    await tester.pumpWidget(
        _host(null, item: _named(productName: 'Aspirin', lotNumber: '')));

    // Assert
    expect(find.text('ในระบบ 10 / นับได้ 8 กล่อง'), findsOneWidget);
  });

  testWidgets('with no name from pos-api the catalogue\'s name is used',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host('Paracetamol', item: _named()));

    // Assert
    expect(find.text('Paracetamol'), findsOneWidget);
  });
}
