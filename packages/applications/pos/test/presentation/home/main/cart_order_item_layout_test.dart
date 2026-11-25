// A cart line laid out in the app's fonts at the widths the cart gets: the
// phone's whole width, the tablet's 340 px panel and the desktop's 400 px,
// in a phone's density and the desktop's (compact).

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/cart_widget.dart';
import '../../../support/app_fonts.dart';

Widget _host(double width, {required double discount}) => MaterialApp(
      theme: CustomTheme.mainTheme,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: CartOrderItem(
              title: 'พาราเซตามอล 500 มก. แผงละ 10 เม็ด',
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
}
