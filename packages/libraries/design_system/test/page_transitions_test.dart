// How a pushed page comes in and goes back: one transition per platform,
// never longer than 300 ms, instant under reduced motion, and a system
// back gesture still reaches a page that refuses to pop.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:design_system/theme/motion.dart';
import 'package:design_system/theme/page_transitions.dart';
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

const _maxTransition = Duration(milliseconds: 300);

/// Sends Android's back-gesture [method] to the app.
Future<void> _backGesture(
  WidgetTester tester,
  String method, [
  Map<String, dynamic>? arguments,
]) async {
  final message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    message,
    (_) {},
  );
}

/// A full Android back swipe from the left edge, released past the commit
/// point.
Future<void> _swipeBack(WidgetTester tester) async {
  await _backGesture(tester, 'startBackGesture', {
    'touchOffset': <double>[5.0, 300.0],
    'progress': 0.0,
    'swipeEdge': 0,
  });
  await tester.pump();
  await _backGesture(tester, 'updateBackGestureProgress', {
    'x': 100.0,
    'y': 300.0,
    'progress': 0.35,
    'swipeEdge': 0,
  });
  await tester.pump();
  await _backGesture(tester, 'commitBackGesture');
  await tester.pumpAndSettle();
}

/// The app with a button that pushes [page]; [appReducesMotion] asks for
/// reduced motion in the app's own MediaQuery, not the platform's.
Future<void> _openApp(
  WidgetTester tester,
  Widget page, {
  bool appReducesMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: CustomTheme.mainTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: appReducesMotion),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => page)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('the page transition of each platform', () {
    for (final theme in [CustomTheme.mainTheme, CustomTheme.darkTheme]) {
      final builders = theme.pageTransitionsTheme.builders;
      final name = theme.brightness.name;

      test('$name: Android previews the page underneath on a back swipe', () {
        expect(
          builders[TargetPlatform.android],
          isA<PredictiveBackPageTransitionsBuilder>(),
        );
      });

      test('$name: iOS and macOS slide as the platform does', () {
        expect(
          builders[TargetPlatform.iOS],
          isA<CupertinoPageTransitionsBuilder>(),
        );
        expect(
          builders[TargetPlatform.macOS],
          isA<CupertinoPageTransitionsBuilder>(),
        );
      });

      test('$name: Windows, Linux and Fuchsia fade forwards', () {
        for (final platform in [
          TargetPlatform.windows,
          TargetPlatform.linux,
          TargetPlatform.fuchsia,
        ]) {
          expect(
            builders[platform],
            isA<FadeForwardsPageTransitionsBuilder>(),
            reason: '$platform',
          );
        }
      });
    }

    test('on the web every platform fades forwards', () {
      final builders = appPageTransitionsTheme(isWeb: true).builders;

      for (final platform in TargetPlatform.values) {
        expect(
          builders[platform],
          isA<FadeForwardsPageTransitionsBuilder>(),
          reason: '$platform',
        );
      }
    });

    testWidgets('none is longer than 300 ms, and back is not slower', (
      tester,
    ) async {
      for (final isWeb in [false, true]) {
        final builders = appPageTransitionsTheme(isWeb: isWeb).builders;
        for (final MapEntry(:key, :value) in builders.entries) {
          expect(value.transitionDuration, AppMotion.medium, reason: '$key');
          expect(
            value.reverseTransitionDuration,
            AppMotion.short,
            reason: '$key',
          );
          expect(value.transitionDuration, lessThanOrEqualTo(_maxTransition));
        }
      }
    });
  });

  group('reduced motion', () {
    setUp(() {
      TestWidgetsFlutterBinding
          .instance
          .platformDispatcher
          .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
    });
    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher
          .clearAccessibilityFeaturesTestValue();
    });

    testWidgets('a page transition takes no time', (tester) async {
      for (final builder in appPageTransitionsTheme(
        isWeb: false,
      ).builders.values) {
        expect(builder.transitionDuration, Duration.zero);
        expect(builder.reverseTransitionDuration, Duration.zero);
      }
    });

    testWidgets('a pushed page is fully shown after one frame', (tester) async {
      // Arrange
      await _openApp(tester, const Scaffold(body: Text('inner')));

      // Act
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();

      // Assert
      expect(find.text('inner'), findsOneWidget);
      expect(find.text('open'), findsNothing);
    });

    testWidgets('going back leaves the page at once', (tester) async {
      // Arrange
      await _openApp(tester, const Scaffold(body: Text('inner')));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Act
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump();

      // Assert
      expect(find.text('inner'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  testWidgets('reduced motion in the app draws a pushed page where it ends', (
    tester,
  ) async {
    // Arrange
    await _openApp(
      tester,
      const Scaffold(body: Text('inner')),
      appReducesMotion: true,
    );

    // Act
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Assert
    final page = find.text('inner');
    final fades = find.ancestor(
      of: page,
      matching: find.byType(FadeTransition),
    );
    for (final fade in tester.widgetList<FadeTransition>(fades)) {
      expect(fade.opacity.value, 1.0);
    }
    final slides = find.ancestor(
      of: page,
      matching: find.byType(SlideTransition),
    );
    for (final slide in tester.widgetList<SlideTransition>(slides)) {
      expect(slide.position.value, Offset.zero);
    }
    expect(fades, findsWidgets);
  });

  group('the Android back swipe', () {
    testWidgets('takes a page that may close back to the one before', (
      tester,
    ) async {
      // Arrange
      await _openApp(tester, const Scaffold(body: Text('inner')));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Act
      await _swipeBack(tester);

      // Assert
      expect(find.text('inner'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('is handed to a page that decides for itself', (tester) async {
      // Arrange
      final asked = <bool>[];
      await _openApp(
        tester,
        PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => asked.add(didPop),
          child: const Scaffold(body: Text('inner')),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Act
      await _swipeBack(tester);

      // Assert
      expect(asked, [false]);
      expect(find.text('inner'), findsOneWidget);
    });
  });
}
