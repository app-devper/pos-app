// The app's product picker dialog with its search
// (StockCountItemPickerWidget): a stock count and a receipt line open it.

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/presentation/stock_count/manage/stock_count_item_picker_widget.dart';
import '../pump.dart';
import 'shell_robot.dart';

const _searchHint = 'ค้นหาสินค้า...';

/// The open picker.
final productPicker = find.byType(StockCountItemPickerWidget);

/// [finder] inside the open picker, hit-testable.
Finder inProductPicker(Finder finder) =>
    find.descendant(of: productPicker, matching: finder).hitTestable();

/// In the open picker: waits for the products, searches [productName] and
/// taps its row. A real catalogue is long, so it is searched, not scrolled.
Future<void> pickProductByName(ShellRobot shell, String productName,
    {Duration timeout = const Duration(seconds: 30)}) async {
  final tester = shell.tester;
  final search = shell.searchField(_searchHint);
  await pumpUntilFound(tester, search);
  // A row of any product means the list has loaded.
  await pumpUntilFound(tester,
      find.descendant(of: productPicker, matching: find.byType(ListTile)),
      timeout: timeout);
  await tester.enterText(search, productName);
  await tester.pump();
  // The search field holds the name too; the row is a ListTile.
  final row = inProductPicker(find.widgetWithText(ListTile, productName));
  await pumpUntilFound(tester, row);
  await tester.tap(row);
  await tester.pump();
}
