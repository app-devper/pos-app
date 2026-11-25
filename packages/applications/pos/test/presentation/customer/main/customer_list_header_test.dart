// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/customer/main/customer_list_header.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('the add button of the narrow customer list is labelled',
      (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    var added = 0;
    await tester.pumpWidget(_host(CustomerListHeader(
      title: 'ข้อมูลลูกค้า',
      backLabel: 'ย้อนกลับ',
      addLabel: 'เพิ่มลูกค้า',
      showAdd: true,
      onBack: () {},
      onAdd: () => added++,
      onSearch: (_) {},
    )));

    // Act
    await tester.tap(find.bySemanticsLabel('เพิ่มลูกค้า'));

    // Assert
    expect(added, 1);
    expect(find.text('ข้อมูลลูกค้า'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the wide customer list has no add button in its header',
      (tester) async {
    // Arrange / Act
    await tester.pumpWidget(_host(CustomerListHeader(
      title: 'ข้อมูลลูกค้า',
      backLabel: 'ย้อนกลับ',
      addLabel: 'เพิ่มลูกค้า',
      showAdd: false,
      onBack: () {},
      onAdd: () {},
      onSearch: (_) {},
    )));

    // Assert
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('the back arrow calls back', (tester) async {
    // Arrange
    var back = 0;
    await tester.pumpWidget(_host(CustomerListHeader(
      title: 'ข้อมูลลูกค้า',
      backLabel: 'ย้อนกลับ',
      addLabel: 'เพิ่มลูกค้า',
      showAdd: true,
      onBack: () => back++,
      onAdd: () {},
      onSearch: (_) {},
    )));

    // Act
    await tester.tap(find.byIcon(Icons.arrow_back_ios));

    // Assert
    expect(back, 1);
  });

  testWidgets('the customer list has a search field that reports each change',
      (tester) async {
    // Arrange
    final searched = <String>[];
    await tester.pumpWidget(_host(CustomerListHeader(
      title: 'ข้อมูลลูกค้า',
      backLabel: 'ย้อนกลับ',
      addLabel: 'เพิ่มลูกค้า',
      showAdd: false,
      onBack: () {},
      onAdd: () {},
      onSearch: searched.add,
    )));

    // Act
    await tester.enterText(
        find.widgetWithText(TextField, 'ค้นหาลูกค้า...'), 'สม');

    // Assert
    expect(searched, ['สม']);
  });
}
