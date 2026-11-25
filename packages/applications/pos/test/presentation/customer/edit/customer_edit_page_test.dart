// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/customer/param.dart';
import 'package:pos/domain/repositories/customer_repository.dart';
import 'package:pos/presentation/customer/edit/customer_edit_page.dart';
import 'package:pos/presentation/customer/edit/customer_edit_view_model.dart';

/// Records what the edit form sends.
class _RecordingRepository implements CustomerRepository {
  CustomerParam? sent;

  @override
  Future<Customer> updateCustomerById(
      String customerId, CustomerParam param) async {
    sent = param;
    return _wholesale;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _wholesale = Customer(
  id: 'c1',
  code: 'CU1',
  name: 'ร้านขายส่ง',
  address: '',
  phone: '0800000000',
  email: '',
  status: 'ACTIVE',
  type: customerTypeWholesaler,
);

void main() {
  tearDown(() async => sl.reset());

  testWidgets('editing only the phone of a wholesale customer keeps its type',
      (tester) async {
    // Arrange
    final repo = _RecordingRepository();
    sl.registerFactory(() => CustomerEditViewModel(customerRepo: repo));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomerEditPage(
          customer: _wholesale,
          onBack: () {},
          onEdit: () {},
          onRemove: () {},
        ),
      ),
    ));
    expect(find.text('ลูกค้าขายส่ง'), findsOneWidget,
        reason: 'the form opens on the customer\'s own type');

    // Act
    await tester.enterText(
        find.widgetWithText(TextFormField, 'โทรศัพท์'), '0811111111');
    await tester.tap(find.text('ยืนยัน'));
    await tester.pump();

    // Assert
    expect(repo.sent?.phone, '0811111111');
    expect(repo.sent?.customerType, customerTypeWholesaler);
  });
}
