// The app's own fonts, loaded for a widget test, so that a layout measured in
// a test is the layout a user gets (flutter_test otherwise draws every glyph
// in the square Ahem font, whose lines are lower than Sarabun's).

// Flutter imports:
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

const _fonts = {
  'Sarabun': [
    'packages/common/assets/font/Sarabun-Regular.ttf',
    'packages/common/assets/font/Sarabun-Medium.ttf',
    'packages/common/assets/font/Sarabun-Bold.ttf',
  ],
  'Roboto': [
    'packages/common/assets/font/roboto_regular.ttf',
    'packages/common/assets/font/roboto_bold.ttf',
  ],
};

/// The phone size the layout tests use.
const phoneSize = Size(360, 640);

/// The desktop size the layout tests use (the E2E suite's surface).
const desktopSize = Size(1400, 900);

/// Loads Sarabun and Roboto, as the app bundles them. Call in setUpAll.
Future<void> loadAppFonts() async {
  for (final MapEntry(key: family, value: assets) in _fonts.entries) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

/// Lays the test's view out at [size] logical pixels, reset after the test.
void useViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Expects [inner]'s rect to lie fully inside [outer]'s.
void expectInside(WidgetTester tester, Finder inner, Finder outer) {
  final box = tester.getRect(outer);
  final text = tester.getRect(inner);
  expect(
    box.contains(text.topLeft) &&
        box.contains(text.bottomRight - const Offset(0.01, 0.01)),
    isTrue,
    reason: '$text is not inside $box',
  );
}
