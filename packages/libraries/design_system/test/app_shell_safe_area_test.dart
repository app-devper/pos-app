import 'package:design_system/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _statusBar = 24.0;

/// The shell at [size], under a status bar [top] px high.
Widget _shell(Size size, {required double top}) => MediaQuery(
  data: MediaQueryData(
    size: size,
    padding: EdgeInsets.only(top: top),
    viewPadding: EdgeInsets.only(top: top),
  ),
  child: MaterialApp(
    home: AppShell(
      title: '',
      brand: 'Devper POS',
      showTopBar: false,
      selectedId: 'one',
      items: const [
        AppShellItem(id: 'one', label: 'Overview', icon: Icons.home),
      ],
      onSelect: (_) {},
      child: const Text('Content'),
    ),
  ),
);

void _useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('on a phone the menu button sits below the status bar', (
    tester,
  ) async {
    // Arrange
    const size = Size(360, 640);
    _useSize(tester, size);

    // Act
    await tester.pumpWidget(_shell(size, top: _statusBar));

    // Assert
    final menu = tester.getRect(find.byTooltip('เมนู'));
    expect(menu.top, greaterThanOrEqualTo(_statusBar));
    expect(
      tester.getRect(find.text('Content')).top,
      greaterThanOrEqualTo(_statusBar),
    );
  });

  for (final size in [const Size(360, 640), const Size(1400, 900)]) {
    testWidgets('with no status bar (the web) nothing moves, $size', (
      tester,
    ) async {
      // Arrange
      _useSize(tester, size);

      // Act
      await tester.pumpWidget(_shell(size, top: 0));

      // Assert: the content starts where it did (under the 60 px phone bar)
      final isPhone = size.width < 600;
      expect(tester.getRect(find.text('Content')).top, isPhone ? 60 : 0);
      if (isPhone) expect(tester.getRect(find.byTooltip('เมนู')).top, 10);
    });
  }
}
