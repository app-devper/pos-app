// The layout sweep: every main screen and dialog the widget tests already
// know how to build, laid out in the app's fonts and theme on a phone
// (360×640) and a desktop (1400×900). Any overflow, or any other error the
// framework reports, fails that screen's test.
//
// It reuses the other tests' fakes; a screen with none is not here (see the
// layout section of docs/e2e-findings.md for what that leaves out).

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import '../support/app_fonts.dart';
import '../support/main_screens.dart';

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  for (final size in [phoneSize, desktopSize]) {
    for (final (screens, isDialog) in [
      (mainPages, false),
      (mainDialogs, true)
    ]) {
      for (final MapEntry(key: name, value: build) in screens.entries) {
        testWidgets('$name lays out without overflow at $size', (tester) async {
          // Arrange
          useViewSize(tester, size);

          // Act
          await showScreen(tester, build(), isDialog: isDialog);

          // Assert
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  // The dialogs on a phone held sideways, the shortest screen: they must fit
  // or scroll.
  for (final MapEntry(key: name, value: build) in mainDialogs.entries) {
    testWidgets('$name lays out without overflow at $landscapePhoneSize',
        (tester) async {
      // Arrange
      useViewSize(tester, landscapePhoneSize);

      // Act
      await showScreen(tester, build(), isDialog: true);

      // Assert
      expect(tester.takeException(), isNull);
    });
  }
}
