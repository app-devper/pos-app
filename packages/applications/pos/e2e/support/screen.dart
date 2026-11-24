// What the app is drawn on: its real fonts and the window size app.dart
// means to use. Both are missing from Task 1's launchApp (see the Task 3
// report); these helpers fill the gap without touching app.dart.

// Flutter imports:
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

/// The size app.dart sets on tester.view. LiveTestWidgetsFlutterBinding lays
/// the app out at its surface size (800x600 unless set) and ignores
/// view.physicalSize, which only reaches MediaQuery; the two then disagree.
const _surfaceSize = Size(1400, 900);

/// Lays the app out at 1400x900 for this test; call before launchApp.
Future<void> useWideSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

// Without the app's own fonts flutter_test draws every glyph as a square one
// em wide, so Thai labels come out far wider than a user sees.

const _families = {
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

/// Registers the fonts pubspec.yaml declares; call once per file, in
/// setUpAll, before the app is first pumped.
Future<void> loadAppFonts() async {
  for (final MapEntry(key: family, value: assets) in _families.entries) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
