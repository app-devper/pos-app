// A tab's name has text of its own: Flutter web writes a tab's label only as
// an aria-label, which Maestro and some screen readers on the web do not read
// as text, so the name sits in a plain node of its own inside the tab.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/core/readable_tab.dart';

/// The tab bar's semantics node whose label is exactly [label], if any.
SemanticsNode? _nodeLabelled(WidgetTester tester, String label) {
  SemanticsNode? found;
  bool visit(SemanticsNode node) {
    if (node.label == label) found = node;
    node.visitChildren(visit);
    return true;
  }

  visit(tester.getSemantics(find.byType(TabBar)));
  return found;
}

void main() {
  testWidgets('each tab of a tab bar has a text node of its own',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(const MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: TabBar(tabs: [ReadableTab('สต็อก'), ReadableTab('ประวัติ')]),
        ),
      ),
    ));

    // Assert
    for (final name in ['สต็อก', 'ประวัติ']) {
      final label = _nodeLabelled(tester, name);
      expect(label, isNotNull, reason: 'no node reads "$name" alone');
      expect(label!.childrenCount, 0, reason: name);
      expect(label.getSemanticsData().role, isNot(SemanticsRole.tab),
          reason: 'the name is in a node of its own, not on the tab');
      expect(label.parent?.getSemanticsData().role, SemanticsRole.tab);
      // The web does not write the name node of a tab into the page (it
      // shows only the tab's aria-label), so the tab carries its name as
      // its identifier too: a test on the web can find it by that.
      expect(label.parent?.getSemanticsData().identifier, name);
    }
    semantics.dispose();
  });
}
