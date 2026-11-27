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

Widget _host({ValueChanged<String>? onCompleted}) => MaterialApp(
      theme: CustomTheme.mainTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showInputNumberDialog(context,
                title: 'จำนวนสินค้า', onCompleted: onCompleted ?? (_) {}),
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

  testWidgets(
      'on a phone held sideways every key of the quantity dialog can be '
      'scrolled to and pressed, and the figure confirmed', (tester) async {
    // Arrange
    useViewSize(tester, landscapePhoneSize);
    final completed = <String>[];
    await tester.pumpWidget(_host(onCompleted: completed.add));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Act: 1, then the bottom row's 0, then confirm
    await tester.tap(find.byKey(const Key('btn_1')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('btn_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_0')));
    await tester.pump();
    await tester.tap(find.text('ยืนยัน'));
    await tester.pumpAndSettle();

    // Assert
    expect(tester.takeException(), isNull);
    expect(completed, ['10']);
  });
}
