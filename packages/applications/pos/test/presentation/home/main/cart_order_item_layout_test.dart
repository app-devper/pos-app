// A cart line laid out in the app's fonts at the widths the cart gets: the
// phone's whole width, the tablet's 340 px panel and the desktop's 400 px,
// in a phone's density and the desktop's (compact).

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/cart_widget.dart';
import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';

const _name = 'พาราเซตามอล 500 มก. แผงละ 10 เม็ด';

Widget _host(double width, {required double discount}) => MaterialApp(
      theme: CustomTheme.mainTheme,
      localizationsDelegates: const [thaiLanguages],
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: CartOrderItem(
              title: _name,
              quantity: 12,
              price: 1234.5,
              unit: 'แผง',
              discount: discount,
              priceDetail: 'ราคาหน้าร้าน',
              allowOversell: false,
              onRemove: () {},
              onAdd: () {},
              onEdit: () {},
              onEditPrice: () {},
              onToggleOversell: () {},
            ),
          ),
        ),
      ),
    );

/// A phone's touch density and the desktop's compact one.
final _densities =
    TargetPlatformVariant(const {TargetPlatform.android, TargetPlatform.macOS});

void main() {
  setUpAll(loadAppFonts);

  for (final width in [phoneSize.width, 340.0, 400.0]) {
    for (final discount in [0.0, 100.0]) {
      testWidgets(
          'a cart line fits its price column at $width px, '
          'discount $discount', (tester) async {
        // Arrange
        useViewSize(tester, phoneSize);

        // Act
        await tester.pumpWidget(_host(width, discount: discount));

        // Assert
        expect(tester.takeException(), isNull);
        final total = discount > 0 ? '฿13,614.00' : '฿14,814.00';
        expectInside(tester, find.text(total), find.byType(ListTile));
      }, variant: _densities);
    }
  }

  // Finding 29, found by the accessibility walk: on a 360 px phone the cart
  // is the screen less its 51 px cart slots, 309 px, and the line's 288 px
  // of buttons and price left its 40 px of padding and the product name no
  // room. A cart that narrow puts the quantity controls on a row of their
  // own, under the name, unit and price.
  testWidgets('a cart line fits the 309 px cart of a 360 px phone',
      (tester) async {
    // Arrange
    useViewSize(tester, phoneSize);

    // Act
    await tester.pumpWidget(_host(phoneSize.width - 51, discount: 0));

    // Assert
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text(_name)).width, greaterThan(0));
  }, variant: _densities);

  for (final width in [phoneSize.width - 51, 400.0]) {
    testWidgets('a $width px cart line lays out the whole product name',
        (tester) async {
      // Arrange
      useViewSize(tester, phoneSize);

      // Act
      await tester.pumpWidget(_host(width, discount: 0));

      // Assert
      expect(tester.takeException(), isNull);
      final name = tester.renderObject<RenderParagraph>(find.text(_name));
      expect(name.didExceedMaxLines, isFalse,
          reason: 'the name is cut short in ${name.size}');
      expectInside(tester, find.text(_name), find.byType(CartOrderItem));
    }, variant: _densities);

    testWidgets('every control of a $width px cart line keeps its name',
        (tester) async {
      // Arrange
      final semantics = tester.ensureSemantics();
      useViewSize(tester, phoneSize);

      // Act
      await tester.pumpWidget(_host(width, discount: 0));

      // Assert
      for (final label in [
        '12x $_name แผง ฿14,814.00 ราคาหน้าร้าน',
        'ลดจำนวน $_name',
        'แก้ไขจำนวน $_name',
        'เพิ่มจำนวน $_name',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      expect(find.byTooltip('อนุญาตขายเกินสต็อก $_name'), findsOneWidget);
      semantics.dispose();
    }, variant: _densities);
  }
}
