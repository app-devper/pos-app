import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

BoxDecoration tagDecoration(WidgetTester tester) => tester
    .widget<DecoratedBox>(find.descendant(
        of: find.byType(AppTag), matching: find.byType(DecoratedBox)))
    .decoration as BoxDecoration;

Color? tagTextColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  final colors = AppColors.light;
  final tones = <AppTagTone, (Color, Color)>{
    AppTagTone.neutral: (colors.surfaceRaised, colors.textPrimary),
    AppTagTone.warning: (colors.statusWarningFill, colors.statusWarningText),
    AppTagTone.danger: (colors.statusDangerFill, colors.statusDangerText),
    AppTagTone.success: (colors.statusSuccessFill, colors.statusSuccessText),
  };

  for (final tone in tones.entries) {
    testWidgets('a ${tone.key.name} tag takes its tone\'s fill and text',
        (tester) async {
      await tester.pumpWidget(themed(AppTag(label: 'ป้าย', tone: tone.key)));

      final (fill, text) = tone.value;
      expect(tagDecoration(tester).color, fill);
      expect(tagTextColor(tester, 'ป้าย'), text);
      expect(tagDecoration(tester).borderRadius,
          BorderRadius.circular(AppRadius.tag));
    });
  }

  testWidgets('a status badge draws as a tag with the same label',
      (tester) async {
    await tester.pumpWidget(
        themed(const StatusBadge(label: 'ยกเลิก', color: CustomColor.error)));

    expect(find.byType(AppTag), findsOneWidget);
    expect(tester.widget<AppTag>(find.byType(AppTag)).tone, AppTagTone.danger);
    expect(find.text('ยกเลิก'), findsOneWidget);
  });
}
