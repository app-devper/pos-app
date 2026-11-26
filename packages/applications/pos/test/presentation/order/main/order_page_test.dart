// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:um/domain/usecase/auth_use_cases.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/order/main/order_list_tile.dart';
import 'package:pos/presentation/order/main/order_page.dart';
import 'package:pos/presentation/order/main/order_view_model.dart';
import '../../../support/app_fonts.dart';
import '../../../support/main_screens.dart';
import 'order_view_model_test.dart' as bills;

/// The bills list of three bills, as an admin sees it.
Widget _billsList() {
  sl.registerFactory(() => OrderViewModel(
        orderRepo: bills.FakeOrderRepository(orders: [
          bills.order('1', 'Cash'),
          bills.order('2', 'PromptPay', status: 'CANCELLED'),
          bills.order('3', 'Cash'),
        ]),
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
}
