// The options of an open dropdown have text of their own: Flutter web writes
// a menu item's label only as an aria-label, which Maestro and some screen
// readers on the web do not read as text, so each option's name sits in a
// plain node of its own inside its menu item.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:design_system/widgets/dropdown_input.dart';

void main() {
  testWidgets('each option of an open dropdown has a text node of its own', (
    tester,
  ) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownInput<String>(
            hintText: 'ร้านขายสินค้า',
            options: const ['ACME', 'Beta'],
            value: null,
            getLabel: (name) => name,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    // Act
    await tester.tap(find.text('ร้านขายสินค้า'));
    await tester.pumpAndSettle();

    // Assert
    for (final name in ['ACME', 'Beta']) {
      final option = tester.getSemantics(find.bySemanticsLabel(name).last);
      expect(option.childrenCount, 0);
      expect(
        option.getSemanticsData().role,
        isNot(SemanticsRole.menuItem),
        reason: 'the name is in a node of its own, not on the menu item',
      );
      expect(option.parent?.getSemanticsData().role, SemanticsRole.menuItem);
    }
    semantics.dispose();
  });

  testWidgets('the chosen option is shown in the closed dropdown', (
    tester,
  ) async {
    // Arrange / Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropdownInput<String>(
            hintText: 'ร้านขายสินค้า',
            options: const ['ACME', 'Beta'],
            value: 'Beta',
            getLabel: (name) => name,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Beta'), findsOneWidget);
  });
}
