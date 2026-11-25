// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/cart_widget.dart';
import '../../../support/app_fonts.dart';

/// In the app's theme and fonts, so a layout error here is one a user gets.
Widget _host(Widget child) =>
    MaterialApp(theme: CustomTheme.mainTheme, home: Scaffold(body: child));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a cart line says which product its quantity belongs to',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(_host(CartOrderItem(
      title: 'Paracetamol 500',
      quantity: 2,
      price: 25,
      unit: 'ชิ้น',
      discount: 0,
      priceDetail: 'ราคาหน้าร้าน',
      allowOversell: false,
      onRemove: () {},
      onAdd: () {},
      onEdit: () {},
      onEditPrice: () {},
      onToggleOversell: () {},
    )));
    // Assert: the visible text is unchanged, the label names the product.
    expect(find.text('2x'), findsOneWidget);
    expect(find.bySemanticsLabel('2x Paracetamol 500'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the button that opens the product picker is labelled',
      (tester) async {
    // Arrange
    var opened = 0;
    await tester.pumpWidget(_host(CartSearchButton(onPressed: () => opened++)));

    // Act
    await tester.tap(find.byTooltip('เลือกสินค้า'));

    // Assert
    expect(opened, 1);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('the button that takes the customer off the sale names them',
      (tester) async {
    // Arrange
    var removed = 0;
    await tester.pumpWidget(_host(CartCustomerRemoveButton(
        customerName: 'สมชาย ใจดี', onPressed: () => removed++)));

    // Act
    await tester.tap(find.byTooltip('นำลูกค้า สมชาย ใจดี ออก'));

    // Assert
    expect(removed, 1);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
