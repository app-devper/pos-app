import 'dart:ui';

import 'package:design_system/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money keeps the given style and draws its figures in even columns', () {
    // Arrange
    const base = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

    // Act
    final money = AppText.money(base);

    // Assert
    expect(money.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(money.fontSize, 18);
    expect(money.fontWeight, FontWeight.bold);
  });

  test('money with no style still draws even figures', () {
    expect(
      AppText.money(null).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('money keeps a style\'s other font features', () {
    // Arrange
    const base = TextStyle(fontFeatures: [FontFeature.slashedZero()]);

    // Act
    final features = AppText.money(base).fontFeatures;

    // Assert
    expect(features, contains(const FontFeature.slashedZero()));
    expect(features, contains(const FontFeature.tabularFigures()));
  });
}
