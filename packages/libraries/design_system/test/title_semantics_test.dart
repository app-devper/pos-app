// A page or dialog title is a header node of its own, with no children: on
// the web Flutter writes only such a node's label into the page as text.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:design_system/widgets/app_bar.dart';
import 'package:design_system/widgets/title_bar.dart';

void _expectHeader(WidgetTester tester, String title) {
  final node = tester.getSemantics(find.bySemanticsLabel(title));
  expect(node.childrenCount, 0, reason: '"$title" is a node of its own');
  expect(node.getSemanticsData().flagsCollection.isHeader, isTrue);
}

void main() {
  testWidgets('a dialog title bar title is a header of its own', (
    tester,
  ) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TitleBar(title: 'เลือกลูกค้า', onBack: () {}, action: 'ยืนยัน'),
        ),
      ),
    );

    // Assert
    _expectHeader(tester, 'เลือกลูกค้า');
    semantics.dispose();
  });

  testWidgets('a page app bar title is a header of its own', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: buildAppBar(
            'รับสินค้า',
            actions: [
              IconButton(
                tooltip: 'ลบ',
                onPressed: () {},
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
    );

    // Assert
    _expectHeader(tester, 'รับสินค้า');
    semantics.dispose();
  });
}
