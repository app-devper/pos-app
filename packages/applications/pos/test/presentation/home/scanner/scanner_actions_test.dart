// The scanner's app-bar actions: the page itself opens the camera plugin,
// which a widget test cannot build, so its two buttons are tested here.

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/scanner/scanner_actions.dart';
import '../../../support/app_languages.dart';
import '../../../support/main_screens.dart';

void main() {
  Future<List<String>> show(WidgetTester tester) async {
    final pressed = <String>[];
    await showScreen(
        tester,
        Scaffold(
          appBar: AppBar(actions: [
            ScannerActions(
              onToggleFlash: () => pressed.add('flash'),
              onSwitchCamera: () => pressed.add('camera'),
            ),
          ]),
        ),
        isDialog: false,
        languages: thaiLanguages);
    return pressed;
  }

  testWidgets('the flash and switch-camera buttons are named in Thai',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    await show(tester);

    // Act
    final flash = find.byTooltip('เปิดหรือปิดไฟแฟลช');
    final camera = find.byTooltip('สลับกล้อง');

    // Assert
    expect(flash, findsOneWidget);
    expect(camera, findsOneWidget);
    for (final (icon, name) in [
      (Icons.flash_on, 'เปิดหรือปิดไฟแฟลช'),
      (Icons.flip_camera_ios, 'สลับกล้อง'),
    ]) {
      final data = tester.getSemantics(find.byIcon(icon)).getSemanticsData();
      expect(data.tooltip, name);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
    }
    semantics.dispose();
  });

  testWidgets('each button does its own thing', (tester) async {
    // Arrange
    final pressed = await show(tester);

    // Act
    await tester.tap(find.byTooltip('เปิดหรือปิดไฟแฟลช'));
    await tester.tap(find.byTooltip('สลับกล้อง'));

    // Assert
    expect(pressed, ['flash', 'camera']);
  });
}
