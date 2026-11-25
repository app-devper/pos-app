// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/receive/main/receive_menu_button.dart';

void main() {
  testWidgets('the narrow receipts list labels the button that opens its menu',
      (tester) async {
    // Arrange
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ReceiveMenuButton(onPressed: () => opened++))));

    // Act
    await tester.tap(find.byTooltip('เมนูใบรับสินค้า'));

    // Assert
    expect(opened, 1);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
