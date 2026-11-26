// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:um/domain/usecase/auth_use_cases.dart';

// Project imports:
import 'package:pos/container.dart';
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
Widget _billDetail({String role = 'ADMIN'}) {
  sl.registerFactory(() => OrderDetailViewModel(
        getRoleUseCase: GetRoleUseCase(bill.FakeLoginRepository(role: role)),
        orderRepo: bill.FakeOrderRepository(
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
}
