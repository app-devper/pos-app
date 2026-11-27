import 'package:design_system/theme/theme.dart';
import 'package:design_system/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'an empty state in a short space scrolls instead of overflowing',
    (tester) async {
      // Arrange: a list column on a phone held sideways leaves little height.
      await tester.pumpWidget(
        MaterialApp(
          theme: CustomTheme.mainTheme,
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: EmptyState(
                    icon: Icons.inbox,
                    title: 'ยังไม่มีรายการ',
                    message: 'เพิ่มรายการแรกได้ที่นี่',
                    actionLabel: 'เพิ่มรายการแรก',
                    onAction: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.drag(find.byType(EmptyState), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.text('เพิ่มรายการแรก').hitTestable(), findsOneWidget);
    },
  );
}
