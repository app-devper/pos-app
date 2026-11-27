// The options of the app's plain dropdowns have text of their own: Flutter
// web writes a menu item's label only as an aria-label, which Maestro and
// some screen readers on the web do not read as text.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/core/readable_option.dart';

/// The open menu's semantics node whose label is exactly [label], if any.
SemanticsNode? _nodeLabelled(WidgetTester tester, String label) {
  SemanticsNode? found;
  bool visit(SemanticsNode node) {
    if (node.label == label &&
        node.getSemanticsData().role != SemanticsRole.menuItem) {
      found = node;
    }
    node.visitChildren(visit);
    return true;
  }

  visit(tester.getSemantics(find.byType(MaterialApp)));
  return found;
}

void main() {
  testWidgets('each option of an open dropdown has a text node of its own',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'การแสดงข้อมูลสินค้า'),
          items: [
            readableOption('a', 'แสดงหน้าร้าน'),
            readableOption('b', 'ไม่แสดงหน้าร้าน'),
          ],
          onChanged: (_) {},
        ),
      ),
    ));

    // Act
    await tester.tap(find.text('การแสดงข้อมูลสินค้า'));
    await tester.pumpAndSettle();

    // Assert
    for (final name in ['แสดงหน้าร้าน', 'ไม่แสดงหน้าร้าน']) {
      final option = _nodeLabelled(tester, name);
      expect(option, isNotNull, reason: 'no node reads "$name" alone');
      expect(option!.childrenCount, 0);
      expect(option.parent?.getSemanticsData().role, SemanticsRole.menuItem);
    }
    semantics.dispose();
  });
}
