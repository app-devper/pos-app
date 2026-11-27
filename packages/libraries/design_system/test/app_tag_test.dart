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

  testWidgets('a status badge given a tone draws as that tag', (tester) async {
    await tester.pumpWidget(themed(
        const StatusBadge.tone(label: 'ยกเลิก', tone: AppTagTone.danger)));

    expect(tester.widget<AppTag>(find.byType(AppTag)).tone, AppTagTone.danger);
    expect(find.text('ยกเลิก'), findsOneWidget);
  });

  // Callers that tell things apart by colour (movement types, roles) keep
  // their colour until their own screen moves to tones.
  for (final color in [Colors.blue, Colors.purple, CustomColor.warning]) {
    testWidgets('a status badge given colour $color keeps it', (tester) async {
      await tester.pumpWidget(themed(StatusBadge(label: 'ขาย', color: color)));

      expect(find.byType(AppTag), findsNothing);
      expect(tagTextColor(tester, 'ขาย'), color);
      final box = tester
          .widget<DecoratedBox>(find.descendant(
              of: find.byType(StatusBadge),
              matching: find.byType(DecoratedBox)))
          .decoration as BoxDecoration;
      expect(box.color, color.withValues(alpha: 0.1));
      expect(box.borderRadius, BorderRadius.circular(AppRadius.tag));
    });
  }
}
