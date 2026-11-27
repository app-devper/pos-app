import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

BoxDecoration decorationOf(WidgetTester tester) => tester
    .widget<DecoratedBox>(find.descendant(
        of: find.byType(AppCard), matching: find.byType(DecoratedBox)))
    .decoration as BoxDecoration;

void main() {
  testWidgets('a card is a hairline box with the card radius and no shadow',
      (tester) async {
    await tester.pumpWidget(themed(const AppCard(child: Text('x'))));

    final decoration = decorationOf(tester);
    expect(decoration.border, Border.all(color: AppColors.light.border));
    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.card));
    expect(decoration.color, AppColors.light.surfaceRaised);
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('a selected card is outlined in the text colour', (tester) async {
    await tester
        .pumpWidget(themed(const AppCard(selected: true, child: Text('x'))));

    expect(decorationOf(tester).border,
        Border.all(color: AppColors.light.textPrimary));
  });

  testWidgets('a muted card sits on the sunken fill', (tester) async {
    await tester
        .pumpWidget(themed(const AppCard(muted: true, child: Text('x'))));

    expect(decorationOf(tester).color, AppColors.light.surfaceSunken);
  });

  testWidgets('a card with onTap is a button and calls it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
        themed(AppCard(onTap: () => taps++, child: const Text('เปิด'))));

    await tester.tap(find.text('เปิด'));

    expect(taps, 1);
    expect(tester.getSemantics(find.byType(InkWell)),
        matchesSemantics(isButton: true, hasTapAction: true, hasFocusAction: true, isFocusable: true, label: 'เปิด'));
  });

  testWidgets('a dark card takes the dark tokens', (tester) async {
    await tester
        .pumpWidget(themed(const AppCard(child: Text('x')), dark: true));

    expect(decorationOf(tester).color, AppColors.dark.surfaceRaised);
  });

  // Ink paints on the nearest Material. Without one inside the card it
  // would paint on the page's, under the card's own fill, and never show.
  testWidgets('ink inside a card paints inside it, with or without onTap',
      (tester) async {
    for (final onTap in <VoidCallback?>[null, () {}]) {
      await tester.pumpWidget(themed(AppCard(
        onTap: onTap,
        child: Ink(color: Colors.red, child: const Text('หมึก')),
      )));

      final material = find.ancestor(
          of: find.text('หมึก'), matching: find.byType(Material));
      expect(
          find.descendant(
              of: find.byType(AppCard), matching: material.first),
          findsOneWidget,
          reason: 'onTap: ${onTap != null}');
      final inner = tester.widget<Material>(material.first);
      expect(inner.type, MaterialType.transparency);
      expect(inner.borderRadius, BorderRadius.circular(AppRadius.card));
    }
  });
}
