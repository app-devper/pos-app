// The cart's quantity dialog (design_system's showInputNumberDialog), laid
// out in the app's fonts at a phone's and a desktop's size.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:design_system/widgets/decimal_input.dart';
import 'package:design_system/widgets/dialogs.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import '../../../support/app_fonts.dart';

Widget _host() => MaterialApp(
      theme: CustomTheme.mainTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showInputNumberDialog(context,
                title: 'จำนวนสินค้า', onCompleted: (_) {}),
            child: const Text('open'),
          ),
        ),
      ),
    );

/// The display box that shows [text]: the decorated Container nearest it.
Finder _displayOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Container)).first;

void main() {
  setUpAll(loadAppFonts);

  for (final size in [phoneSize, desktopSize]) {
    testWidgets(
        'the quantity dialog shows its title and the typed figure '
        'whole, without overflow, $size', (tester) async {
      // Arrange
      useViewSize(tester, size);
      await tester.pumpWidget(_host());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Act
      for (final digit in ['1', '2', '5']) {
        await tester.tap(find.byKey(Key('btn_$digit')));
        await tester.pump();
      }

      // Assert
      expect(tester.takeException(), isNull);
      final title = find.descendant(
          of: find.byType(DecimalInput), matching: find.text('จำนวนสินค้า'));
      expectInside(tester, title, _displayOf('125'));
      expectInside(tester, find.text('125'), _displayOf('125'));
    });
  }
}
