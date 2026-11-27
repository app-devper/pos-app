import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Color? tileFill(WidgetTester tester) => (tester
        .widget<DecoratedBox>(find
            .descendant(
                of: find.byType(FigureTile), matching: find.byType(DecoratedBox))
            .first)
        .decoration as BoxDecoration)
    .color;

void main() {
  testWidgets('a figure tile shows its label and value', (tester) async {
    await tester.pumpWidget(themed(const FigureTile(
        icon: Icons.inventory_2_outlined, label: 'สินค้า', value: '152')));

    expect(find.text('สินค้า'), findsOneWidget);
    expect(find.text('152'), findsOneWidget);
    expect(tileFill(tester), AppColors.light.surfaceRaised);
  });

  testWidgets('a warning tile takes the warning fill and text', (tester) async {
    await tester.pumpWidget(themed(const FigureTile(
        icon: Icons.warning_amber_outlined,
        label: 'ใกล้หมด',
        value: '4',
        tone: AppTagTone.warning)));

    expect(tileFill(tester), AppColors.light.statusWarningFill);
    expect(tester.widget<Text>(find.text('4')).style?.color,
        AppColors.light.statusWarningText);
  });
}
