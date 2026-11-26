// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/cart_widget.dart';
import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';

/// In the app's theme, fonts and (Thai unless [languages] says otherwise)
/// strings, so a layout error here is one a user gets.
Widget _host(Widget child, {TestLanguages languages = thaiLanguages}) =>
    MaterialApp(
      theme: CustomTheme.mainTheme,
      localizationsDelegates: [languages],
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a cart line quantity button says which line it changes',
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
    // Assert: the visible text is unchanged, the label names the line (the
    // line's own node reads the quantity: text_beside_controls_semantics_test)
    expect(find.text('2x'), findsOneWidget);
    expect(find.bySemanticsLabel('แก้ไขจำนวน Paracetamol 500 ชิ้น'),
        findsOneWidget);
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

  testWidgets('in English the cart buttons are named in English',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(
      Row(children: [
        CartSearchButton(onPressed: () {}),
        CartCustomerRemoveButton(customerName: 'Ann', onPressed: () {}),
      ]),
      languages: englishLanguages,
    ));

    // Assert
    expect(find.byTooltip('Choose product'), findsOneWidget);
    expect(find.byTooltip('Remove customer Ann'), findsOneWidget);
  });
}
