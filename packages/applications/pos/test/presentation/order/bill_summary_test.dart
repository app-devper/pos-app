// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:design_system/theme/text_styles.dart';
import 'package:design_system/theme/theme.dart';
import 'package:design_system/widgets/snack_bar.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/order/bill_summary.dart';
import '../../support/app_fonts.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('an admin reads the total, cost and profit in Thai',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(
        _host(const BillSummary(total: 75, totalCost: 30, showCost: true)));

    // Assert
    expect(find.text('ยอดรวม'), findsOneWidget);
    expect(find.text('฿ 75.00'), findsOneWidget);
    expect(find.text('ต้นทุน'), findsOneWidget);
    expect(find.text('฿ 30.00'), findsOneWidget);
    expect(find.text('กำไร'), findsOneWidget);
    expect(find.text('฿ 45.00'), findsOneWidget);
    expect(find.textContaining('Total'), findsNothing);
  });

  testWidgets(
      'the foot\'s figures are money: their figures in even columns, '
      'from design_system\'s one money style', (tester) async {
    // Arrange / Act
    await tester.pumpWidget(
        _host(const BillSummary(total: 75, totalCost: 30, showCost: true)));

    // Assert
    for (final figure in ['฿ 75.00', '฿ 30.00', '฿ 45.00']) {
      final style = tester.widget<Text>(find.text(figure)).style!;
      expect(style.fontFeatures, AppText.money(null).fontFeatures,
          reason: figure);
    }
  });

  testWidgets('anyone else reads only the total', (tester) async {
    // Arrange / Act
    await tester.pumpWidget(
        _host(const BillSummary(total: 75, totalCost: 30, showCost: false)));

    // Assert
    expect(find.text('ยอดรวม'), findsOneWidget);
    expect(find.text('ต้นทุน'), findsNothing);
    expect(find.text('กำไร'), findsNothing);
  });

  test('a line reads its cost and profit in Thai', () {
    // Act
    final text = costAndProfitText(cost: 20, profit: 30);

    // Assert
    expect(text, 'ต้นทุน: 20.00  กำไร: 30.00');
  });

  // On the web a text merged into a node with children is written as an
  // aria-label only, which Maestro cannot read: each row of the foot is a
  // leaf node of its own (the bills list merged its foot into the page).
  testWidgets('each row of the foot is one node of its own', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    // Act
    await tester.pumpWidget(_host(Semantics(
        container: true,
        child: const BillSummary(total: 950, totalCost: 380, showCost: true))));

    // Assert
    for (final row in ['ยอดรวม ฿ 950.00', 'ต้นทุน ฿ 380.00', 'กำไร ฿ 570.00']) {
      final node = tester.getSemantics(find.bySemanticsLabel(row));
      expect(node.childrenCount, 0, reason: row);
    }
    semantics.dispose();
  });

  group('the foot\'s look', () {
    setUpAll(loadAppFonts);

    /// A list over the foot, as the bills list and a bill lay them out.
    Widget page() => MaterialApp(
          theme: CustomTheme.mainTheme,
          home: Scaffold(
            body: Column(children: [
              Expanded(child: ListView()),
              const BillSummary(total: 75, totalCost: 30, showCost: true),
            ]),
          ),
        );

    testWidgets('the foot is a raised surface with a top border',
        (tester) async {
      // Arrange / Act
      await tester.pumpWidget(page());

      // Assert
      final box = tester.widget<DecoratedBox>(find
          .descendant(
              of: find.byType(BillSummary), matching: find.byType(DecoratedBox))
          .first);
      final decoration = box.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, greaterThan(0));
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('ยอดรวม is emphasised over cost and profit', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(page());

      // Assert
      double sizeOf(String text) => tester
          .renderObject<RenderParagraph>(find.text(text))
          .text
          .style!
          .fontSize!;
      expect(sizeOf('฿ 75.00'), greaterThan(sizeOf('฿ 30.00')));
      expect(sizeOf('ยอดรวม'), greaterThan(sizeOf('ต้นทุน')));
    });

    testWidgets('a success bar on a wide screen leaves the foot readable',
        (tester) async {
      // Arrange
      useViewSize(tester, desktopSize);
      await tester.pumpWidget(page());

      // Act
      CustomSnackBar(
              key: UniqueKey(),
              context: tester.element(find.byType(BillSummary)))
          .showSnackBar(text: 'ขายสำเร็จ เลขที่บิล OD_1');
      await tester.pumpAndSettle();

      // Assert
      final bar = tester.getRect(find.byType(SnackBar));
      for (final text in ['ยอดรวม', '฿ 75.00', 'ต้นทุน', 'กำไร']) {
        expect(bar.overlaps(tester.getRect(find.text(text))), isFalse,
            reason: '$text under the bar $bar');
        expect(find.text(text).hitTestable(), findsOneWidget, reason: text);
      }
    });
  });

  group('as a page\'s bottom bar', () {
    setUpAll(loadAppFonts);

    for (final showCost in [true, false]) {
      testWidgets(
          'the foot keeps clear of the gesture bar\'s inset, '
          'showCost=$showCost', (tester) async {
        // Arrange: a phone with a 34 px bottom inset
        useViewSize(tester, phoneSize);
        tester.view.padding = const FakeViewPadding(bottom: 34);
        addTearDown(tester.view.resetPadding);

        // Act
        await tester.pumpWidget(MaterialApp(
          theme: CustomTheme.mainTheme,
          home: Scaffold(
            body: ListView(),
            bottomNavigationBar:
                BillSummary(total: 75, totalCost: 30, showCost: showCost),
          ),
        ));

        // Assert
        final insetTop = phoneSize.height - 34;
        for (final text in ['ยอดรวม', if (showCost) 'กำไร']) {
          expect(tester.getRect(find.text(text)).bottom,
              lessThanOrEqualTo(insetTop),
              reason: '$text above the inset');
        }
        expect(
            tester.getRect(find.byType(BillSummary)).bottom, phoneSize.height,
            reason: 'its surface still reaches the screen\'s edge');
      });
    }
  });
}
