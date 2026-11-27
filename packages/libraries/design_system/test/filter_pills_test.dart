import 'dart:ui' show Tristate;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

const items = [
  FilterPill(value: 'all', label: 'ทั้งหมด', count: 152),
  FilterPill(value: 'low', label: 'ใกล้หมด', count: 4, tone: AppTagTone.warning),
  FilterPill(value: 'out', label: 'หมด'),
];

Color? fillOf(WidgetTester tester, String label) => (tester
        .widget<DecoratedBox>(find
            .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
            .first)
        .decoration as BoxDecoration)
    .color;

void main() {
  testWidgets('the selected pill is filled; a count follows its label',
      (tester) async {
    await tester.pumpWidget(themed(
        FilterPills<String>(items: items, selected: 'all', onSelected: (_) {})));

    expect(fillOf(tester, 'ทั้งหมด 152'), AppColors.light.primaryFill);
    expect(tester.widget<Text>(find.text('ทั้งหมด 152')).style?.color,
        AppColors.light.onPrimaryFill);
    expect(fillOf(tester, 'ใกล้หมด 4'), AppColors.light.statusWarningFill);
    expect(fillOf(tester, 'หมด'), AppColors.light.surfaceRaised);
  });

  testWidgets('a tap reports the pill\'s value', (tester) async {
    final chosen = <String>[];
    await tester.pumpWidget(themed(FilterPills<String>(
        items: items, selected: 'all', onSelected: chosen.add)));

    await tester.tap(find.text('หมด'));

    expect(chosen, ['out']);
  });

  testWidgets('each pill is a button at least as tall as the touch floor, '
      'and says which one is selected', (tester) async {
    await tester.pumpWidget(themed(
        FilterPills<String>(items: items, selected: 'low', onSelected: (_) {})));

    for (final pill in find.byType(InkWell).evaluate()) {
      expect(pill.size!.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    }
    final selected = tester.getSemantics(find.ancestor(
        of: find.text('ใกล้หมด 4'), matching: find.byType(InkWell)));
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets('scrollable pills stay on one row in a narrow space',
      (tester) async {
    await tester.pumpWidget(themed(SizedBox(
      width: 160,
      child: FilterPills<String>(
          items: items, selected: 'all', onSelected: (_) {}, scrollable: true),
    )));

    expect(tester.takeException(), isNull);
    final tops = [for (final i in items) tester.getTopLeft(find.textContaining(i.label).first).dy];
    expect(tops.toSet(), hasLength(1));
  });
}
