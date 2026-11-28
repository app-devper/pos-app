// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/widgets/filter_pills.dart';
import 'package:design_system/widgets/snack_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:um/domain/usecase/auth_use_cases.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/order/bill_summary.dart';
import 'package:pos/presentation/order/main/order_list_tile.dart';
import 'package:pos/presentation/order/main/order_page.dart';
import 'package:pos/presentation/order/main/order_view_model.dart';
import '../../../support/app_fonts.dart';
import '../../../support/main_screens.dart';
import 'order_view_model_test.dart' as bills;

/// The bills list of three bills, as an admin sees it, inside a shell's
/// Scaffold; its loads fail with [throws].
Widget _billsList({Object? throws}) {
  sl.registerFactory(() => OrderViewModel(
        orderRepo: bills.FakeOrderRepository(orders: [
          bills.order('1', 'Cash'),
          bills.order('2', 'PromptPay', status: 'CANCELLED'),
          bills.order('3', 'Cash'),
        ], throws: throws),
        getRoleUseCase:
            GetRoleUseCase(bills.FakeLoginRepository(role: 'ADMIN')),
      ));
  return const Scaffold(body: OrderPage());
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  testWidgets('the bills list separates its rows with the theme\'s divider',
      (tester) async {
    // Arrange
    useViewSize(tester, phoneSize);

    // Act
    await showScreen(tester, _billsList(), isDialog: false);

    // Assert
    expect(find.byType(OrderListTile), findsNWidgets(3));
    final list = find.byType(ListView);
    expect(find.descendant(of: list, matching: find.byType(Divider)),
        findsNWidgets(2));
  });

  group('on a 360x800 phone a floating bar leaves the foot readable', () {
    /// The whole foot (ยอดรวม, ต้นทุน, กำไร) is clear of the bar's visible
    /// surface.
    void expectFootClear(WidgetTester tester) {
      final bar = find.descendant(
          of: find.byType(SnackBar), matching: find.byType(Material));
      expect(bar, findsWidgets);
      final barRect = tester.getRect(bar.first);
      final foot = tester.getRect(find.byType(BillSummary));
      expect(foot.overlaps(barRect), isFalse,
          reason: 'foot $foot, bar $barRect');
      expect(find.text('ยอดรวม').hitTestable(), findsOneWidget);
    }

    testWidgets('the list\'s error bar', (tester) async {
      // Arrange
      useViewSize(tester, const Size(360, 800));

      // Act
      await showScreen(tester, _billsList(throws: Exception('offline')),
          isDialog: false);

      // Assert
      expectFootClear(tester);
    });

    testWidgets('a success bar shown from the list', (tester) async {
      // Arrange
      useViewSize(tester, const Size(360, 800));
      await showScreen(tester, _billsList(), isDialog: false);

      // Act
      CustomSnackBar(
              key: const Key('snackbar'),
              context: tester.element(find.text('ยอดรวม')))
          .showSnackBar(text: 'done');
      await tester.pumpAndSettle();

      // Assert
      expectFootClear(tester);
    });
  });

  testWidgets('an admin chooses the channel with the redesign\'s pills',
      (tester) async {
    useViewSize(tester, phoneSize);
    await showScreen(tester, _billsList(), isDialog: false);

    final pills = find.byType(FilterPills<String>);
    expect(pills, findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(
        [for (final p in tester.widget<FilterPills<String>>(pills).items) p.label],
        ['All', 'Store', 'Online']);

    await tester.tap(find.text('Store'));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<FilterPills<String>>(pills).selected, 'Store');
  });
}
