// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:design_system/widgets/snack_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:um/domain/usecase/auth_use_cases.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/presentation/order/bill_summary.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/presentation/order/detail/order_detail_page.dart';
import 'package:pos/presentation/order/detail/order_detail_view_model.dart';
import '../../../support/app_fonts.dart';
import '../../../support/app_languages.dart';
import '../../../support/main_screens.dart';
import '../../../support/manage_screens.dart';
import 'order_detail_view_model_test.dart' as bill;

/// Bill order-1, opened over the bills list by [role].
Widget _billDetail({String role = 'ADMIN', Object? getByIdThrows}) {
  sl.registerFactory(() => OrderDetailViewModel(
        getRoleUseCase: GetRoleUseCase(bill.FakeLoginRepository(role: role)),
        orderRepo: bill.FakeOrderRepository(
            getByIdThrows: getByIdThrows,
            orderDetail: OrderDetail(
              id: 'order-1',
              createdDate: '2026-11-26T10:00:00Z',
              items: const [],
              total: 0,
              totalCost: 0,
              discount: 0,
              type: 'Cash',
              code: 'OD_1',
              customerCode: '',
              customerName: '',
            )),
        supplierRepo: bill.FakeSupplierRepository(
            supplier: Supplier(
                id: 's1', name: 'ร้าน', address: '', phone: '', taxId: '')),
        customerRepo: bill.FakeCustomerRepository(),
        productRepo: bill.FakeCatalogueRepository(),
      ));
  return pushedOver(const OrderDetailPage(orderId: 'order-1'));
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(() async => sl.reset());

  for (final role in ['ADMIN', 'USER']) {
    testWidgets('the bill\'s title fits its bar at 320 px, for $role',
        (tester) async {
      // Arrange
      useViewSize(tester, const Size(320, 640));

      // Act
      await showScreen(tester, _billDetail(role: role),
          isDialog: false, languages: thaiLanguages);

      // Assert
      final title = tester.renderObject<RenderParagraph>(find.descendant(
          of: find.byType(AppBar), matching: find.text('รายละเอียดบิล')));
      expect(title.size.width,
          greaterThanOrEqualTo(title.getMaxIntrinsicWidth(double.infinity)));
      expect(tester.takeException(), isNull);
    });
  }

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

    testWidgets('the bill\'s error bar', (tester) async {
      // Arrange
      useViewSize(tester, const Size(360, 800));

      // Act
      await showScreen(tester, _billDetail(getByIdThrows: Exception('offline')),
          isDialog: false, languages: thaiLanguages);

      // Assert
      expectFootClear(tester);
    });

    testWidgets('a success bar shown from the bill', (tester) async {
      // Arrange
      useViewSize(tester, const Size(360, 800));
      await showScreen(tester, _billDetail(),
          isDialog: false, languages: thaiLanguages);

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
}
