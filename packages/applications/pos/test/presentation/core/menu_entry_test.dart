// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/core/menu_entry.dart';

void main() {
  // Flutter web writes a menuitem's name as an aria-label only, which
  // Maestro (and a find by text in the page) cannot read; a button's name
  // is written as text.
  testWidgets(
      'a command menu\'s item is a button named in full, not a menuitem, '
      'and calls its action', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    var chosen = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PopupMenuButton<int>(
          tooltip: 'เมนูทดสอบ',
          onSelected: (_) => chosen++,
          itemBuilder: (_) => [
            commandMenuItem(
                value: 1,
                icon: Icons.delete,
                text: 'ลบรายการ',
                name: 'ลบรายการ 2x ชา ฿40.00'),
          ],
        ),
      ),
    ));
    await tester.tap(find.byTooltip('เมนูทดสอบ'));
    await tester.pumpAndSettle();

    // Act
    final item = tester
        .getSemantics(find.bySemanticsLabel('ลบรายการ 2x ชา ฿40.00'))
        .getSemanticsData();
    await tester.tap(find.bySemanticsLabel('ลบรายการ 2x ชา ฿40.00'));
    await tester.pumpAndSettle();

    // Assert
    expect(item.role, isNot(SemanticsRole.menuItem));
    expect(item.flagsCollection.isButton, isTrue);
    expect(item.hasAction(SemanticsAction.tap), isTrue);
    expect(chosen, 1);
    semantics.dispose();
  });
}
