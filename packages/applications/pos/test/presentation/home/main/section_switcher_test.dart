// Switching the shell's sections cross-fades the content area: quick,
// never in the way of a tap, and instant under reduced motion.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/section_switcher.dart';

const _maxTransition = Duration(milliseconds: 300);
const _area = Size(400, 300);

/// A section page that counts its taps and how often it was created; a
/// tap is also logged as `name#n`, n its creation's place in [created].
class _Section extends StatefulWidget {
  final String name;
  final List<String> created;
  final List<String> taps;
  final List<String> tapsByPlace;

  const _Section(this.name,
      {required this.created, required this.taps, required this.tapsByPlace});

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late final int _place;

  @override
  void initState() {
    super.initState();
    widget.created.add(widget.name);
    _place = widget.created.length;
  }

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () {
          widget.taps.add(widget.name);
          widget.tapsByPlace.add('${widget.name}#$_place');
        },
        child: Text(widget.name),
      );
}

class _Harness {
  final created = <String>[];
  final taps = <String>[];
  final tapsByPlace = <String>[];

  Future<void> show(WidgetTester tester, String section,
      {bool reduceMotion = false}) {
    return tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          // The content area, as the shell's Expanded hands it over.
          body: SizedBox.fromSize(
            size: _area,
            child: SectionSwitcher(
              section: section,
              child: _Section(section,
                  created: created, taps: taps, tapsByPlace: tapsByPlace),
            ),
          ),
        ),
      ),
    ));
  }
}

FadeTransition _fadeOf(WidgetTester tester, String section) =>
    tester.widget<FadeTransition>(find
        .ancestor(of: find.text(section), matching: find.byType(FadeTransition))
        .first);

void main() {
  testWidgets('a new section fades in and is done within 300 ms',
      (tester) async {
    // Arrange
    final app = _Harness();
    await app.show(tester, 'selling');

    // Act
    await app.show(tester, 'bills');
    await tester.pump(const Duration(milliseconds: 50));

    // Assert
    expect(_fadeOf(tester, 'bills').opacity.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 10),
        EnginePhase.sendSemanticsUpdate, _maxTransition);
    expect(find.text('selling'), findsNothing);
    expect(_fadeOf(tester, 'bills').opacity.value, 1.0);
  });

  testWidgets('the section going out takes no taps and is not read out',
      (tester) async {
    // Arrange
    final app = _Harness();
    final semantics = tester.ensureSemantics();
    await app.show(tester, 'selling');

    // Act
    await app.show(tester, 'bills');
    await tester.pump(const Duration(milliseconds: 50));

    // Assert
    expect(find.text('selling'), findsOneWidget);
    expect(find.text('selling').hitTestable(), findsNothing);
    expect(find.semantics.byLabel('selling'), findsNothing);
    expect(find.text('bills').hitTestable(), findsOneWidget);
    expect(find.semantics.byLabel('bills'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a tap on the section coming in counts at once', (tester) async {
    // Arrange
    final app = _Harness();
    await app.show(tester, 'selling');

    // Act
    await app.show(tester, 'bills');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('bills'));

    // Assert
    expect(app.taps, ['bills']);
  });

  testWidgets('both sections fill the content area while they fade',
      (tester) async {
    // Arrange
    final app = _Harness();
    await app.show(tester, 'selling');

    // Act
    await app.show(tester, 'bills');
    await tester.pump(const Duration(milliseconds: 50));

    // Assert
    for (final name in ['selling', 'bills']) {
      final page =
          find.ancestor(of: find.text(name), matching: find.byType(_Section));
      expect(tester.getSize(page), _area, reason: name);
    }
  });

  testWidgets('the section already shown keeps its page', (tester) async {
    // Arrange
    final app = _Harness();
    await app.show(tester, 'selling');

    // Act
    await app.show(tester, 'selling');
    await tester.pumpAndSettle();

    // Assert
    expect(app.created, ['selling']);
    expect(find.byType(FadeTransition), findsWidgets);
  });

  testWidgets('under reduced motion the new section is whole after a frame',
      (tester) async {
    // Arrange
    final app = _Harness();
    await app.show(tester, 'selling', reduceMotion: true);

    // Act
    await app.show(tester, 'bills', reduceMotion: true);
    await tester.pump();

    // Assert
    expect(find.text('selling'), findsNothing);
    expect(_fadeOf(tester, 'bills').opacity.value, 1.0);
  });

  testWidgets('A, B and back to A mid-fade: only the top one is live',
      (tester) async {
    // Arrange
    final app = _Harness();
    await app.show(tester, 'selling');

    // Act
    await app.show(tester, 'bills');
    await tester.pump(const Duration(milliseconds: 50));
    await app.show(tester, 'selling');
    await tester.pump(const Duration(milliseconds: 50));

    // Assert: bills, caught early in its fade-in, has already faded out;
    // the first selling is fading, the new one on top is the only live one
    expect(tester.takeException(), isNull);
    expect(app.created, ['selling', 'bills', 'selling']);
    expect(find.text('bills'), findsNothing);
    expect(find.byType(_Section), findsNWidgets(2));
    expect(find.text('selling').hitTestable(), findsOneWidget);
    await tester.tap(find.text('selling').hitTestable());
    expect(app.tapsByPlace, ['selling#3']);
    expect(find.semantics.byLabel('selling'), findsOneWidget);

    // Assert: within 300 ms it is one page (the tap's ripple runs on)
    await tester.pump(_maxTransition);
    expect(find.byType(_Section), findsOneWidget);
    expect(app.created, ['selling', 'bills', 'selling']);
  });
}
