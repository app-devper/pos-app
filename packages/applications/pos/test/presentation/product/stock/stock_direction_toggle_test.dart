// The stock adjustment's add / take toggle: each side is a button named by
// its text, which also carries that text as its identifier (the web writes a
// toggle's name only as an aria-label, never as text).

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/product/stock/stock_direction_toggle.dart';

/// The toggle's semantics node whose identifier is [identifier], if any.
SemanticsNode? _nodeIdentified(WidgetTester tester, String identifier) {
  SemanticsNode? found;
  bool visit(SemanticsNode node) {
    if (node.identifier == identifier) found = node;
    node.visitChildren(visit);
    return true;
  }

  visit(tester.getSemantics(find.byType(ToggleButtons)));
  return found;
}

void main() {
  testWidgets('each side of the toggle is named and identified by its text',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    final chosen = <bool>[];

    // Act
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StockDirectionToggle(isIncrease: true, onChanged: chosen.add),
      ),
    ));

    // Assert
    for (final side in ['เพิ่มสต็อก', 'ลดสต็อก']) {
      final node = _nodeIdentified(tester, side);
      expect(node, isNotNull, reason: 'no node identified as "$side"');
      expect(node!.label, side);
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    }
    await tester.tap(find.text('ลดสต็อก'));
    expect(chosen, [false]);
    semantics.dispose();
  });
}
