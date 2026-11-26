// The จัดการ menu: its titles come from the app's strings, so the English
// build is English and the Thai one keeps the titles robots match.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/home/main/home_database_page.dart';
import '../../../support/app_languages.dart';

Future<void> _openMenu(WidgetTester tester, {required bool thai}) =>
    tester.pumpWidget(MaterialApp(
      localizationsDelegates: [thai ? thaiLanguages : englishLanguages],
      home: const Scaffold(body: HomeDatabasePage()),
    ));

void main() {
  testWidgets('the menu is titled in Thai', (tester) async {
    // Act
    await _openMenu(tester, thai: true);

    // Assert
    for (final title in [
      'ร้านค้าของฉัน',
      'จัดการลูกค้า',
      'จัดการผู้ใช้งาน',
      'ใบรับสินค้า',
      'นับสต็อก',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('the menu is titled in English', (tester) async {
    // Act
    await _openMenu(tester, thai: false);

    // Assert
    for (final title in [
      'My store',
      'Customers',
      'Users',
      'Goods receipts',
      'Stock counts',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('ใบรับสินค้า'), findsNothing);
  });
}
