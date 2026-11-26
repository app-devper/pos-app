// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/core/more_commands_button.dart';
import '../../support/app_languages.dart';

void main() {
  testWidgets(
      'a list\'s commands button is a vertical ellipsis named '
      'คำสั่งเพิ่มเติม, not a second menu', (tester) async {
    // Arrange
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [thaiLanguages],
        home: Scaffold(body: MoreCommandsButton(onPressed: () => opened++))));

    // Act
    await tester.tap(find.byTooltip('คำสั่งเพิ่มเติม'));

    // Assert
    expect(opened, 1);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(tester.getSize(find.byType(IconButton)).shortestSide,
        greaterThanOrEqualTo(48));
  });

  testWidgets('in English the commands button is named in English',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [englishLanguages],
        home: Scaffold(body: MoreCommandsButton(onPressed: () {}))));

    // Assert
    expect(find.byTooltip('More commands'), findsOneWidget);
  });
}
