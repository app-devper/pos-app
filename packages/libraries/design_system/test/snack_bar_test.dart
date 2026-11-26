import 'package:design_system/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// An app whose home is a plain screen; [showFrom] pushes a second screen and
/// hands back that screen's context, the one a page passes to its bar.
class _Harness {
  final navigatorKey = GlobalKey<NavigatorState>();

  Widget get app => MaterialApp(
    navigatorKey: navigatorKey,
    home: const Scaffold(body: Text('home')),
  );

  Future<BuildContext> pushScreen(WidgetTester tester) async {
    late BuildContext screenContext;
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: Builder(
            builder: (context) {
              screenContext = context;
              return const Text('screen');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return screenContext;
  }
}

/// The bar as drawn: its surface, inside the margins around it.
final _barSurface = find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

void main() {
  testWidgets('a success bar closes by itself after four seconds', (
    tester,
  ) async {
    // Arrange
    final harness = _Harness();
    await tester.pumpWidget(harness.app);
    final context = await harness.pushScreen(tester);

    // Act
    CustomSnackBar(
      key: UniqueKey(),
      context: context,
    ).showSnackBar(text: 'Add success');
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    final shownAtThreeSeconds = find.text('Add success').evaluate().isNotEmpty;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Assert
    expect(shownAtThreeSeconds, isTrue);
    expect(find.text('Add success'), findsNothing);
  });

  testWidgets('Clear on a success bar works after its screen was closed', (
    tester,
  ) async {
    // Arrange
    final harness = _Harness();
    await tester.pumpWidget(harness.app);
    final context = await harness.pushScreen(tester);
    CustomSnackBar(
      key: UniqueKey(),
      context: context,
    ).showSnackBar(text: 'Add success');
    await tester.pump();
    harness.navigatorKey.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Act
    await tester.tap(find.text('Clear').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Assert
    expect(tester.takeException(), isNull);
    expect(find.text('Add success'), findsNothing);
  });

  testWidgets('an error bar with an action stays until it is cleared', (
    tester,
  ) async {
    // Arrange
    final harness = _Harness();
    await tester.pumpWidget(harness.app);
    final context = await harness.pushScreen(tester);

    // Act
    CustomSnackBar(
      key: UniqueKey(),
      context: context,
    ).showErrorSnackBar('ไม่พบสินค้า', action: true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));

    // Assert
    expect(find.text('Error: ไม่พบสินค้า'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  for (final (kind, show) in <(String, void Function(CustomSnackBar))>[
    ('success', (bar) => bar.showSnackBar(text: 'Add success')),
    ('error', (bar) => bar.showErrorSnackBar('ไม่พบสินค้า')),
    ('loading', (bar) => bar.showLoadingSnackBar()),
  ]) {
    testWidgets('the $kind bar floats, at most 480 px wide on a wide screen', (
      tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final harness = _Harness();
      await tester.pumpWidget(harness.app);
      final context = await harness.pushScreen(tester);

      // Act
      show(CustomSnackBar(key: UniqueKey(), context: context));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.behavior, SnackBarBehavior.floating);
      expect(tester.getSize(_barSurface).width, lessThanOrEqualTo(480));
    });
  }

  testWidgets('a bar on a phone floats across the screen, inside its margins', (
    tester,
  ) async {
    // Arrange
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = _Harness();
    await tester.pumpWidget(harness.app);
    final context = await harness.pushScreen(tester);

    // Act
    CustomSnackBar(
      key: UniqueKey(),
      context: context,
    ).showSnackBar(text: 'Add success');
    await tester.pumpAndSettle();

    // Assert
    final rect = tester.getRect(_barSurface);
    expect(tester.takeException(), isNull);
    expect(rect.left, greaterThan(0));
    expect(rect.right, lessThan(360));
  });
}
