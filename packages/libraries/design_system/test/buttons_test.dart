import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  for (final dark in [false, true]) {
    final colors = dark ? AppColors.dark : AppColors.light;
    testWidgets('the primary button is the primary fill (dark=$dark)',
        (tester) async {
      await tester.pumpWidget(
          themed(ButtonPrimary(text: 'บันทึก', onClicked: () {}), dark: dark));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor?.resolve({}), colors.primaryFill);
      expect(tester.widget<Text>(find.text('บันทึก')).style?.color,
          colors.onPrimaryFill);
    });

    testWidgets('the secondary button is an outline (dark=$dark)',
        (tester) async {
      await tester.pumpWidget(themed(
          ButtonSecondary(text: 'ยกเลิก', onClicked: () {}),
          dark: dark));

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.style?.side?.resolve({})?.color, colors.border);
      expect(tester.widget<Text>(find.text('ยกเลิก')).style?.color,
          colors.textPrimary);
    });
  }
}
