// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/customer/param.dart';
import 'package:pos/domain/repositories/customer_repository.dart';
import 'package:pos/localizations/language/language_en.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/customer/add/customer_add_view_model.dart';
import 'package:pos/presentation/customer/main/customer_page.dart';
import 'package:pos/presentation/customer/main/customer_view_model.dart';
import 'package:pos/presentation/customer/main/customers_view_model.dart';

/// The server's customers: an add lands here, as on pos-api.
class _ServerRepository implements CustomerRepository {
  final customers = <Customer>[_customer('1', 'ลูกค้าเดิม')];

  @override
  Future<List<Customer>> getLocalCustomers() async => List.of(customers);

  @override
  Future<Customer> createCustomer(CustomerParam param) async {
    final created = _customer('${customers.length + 1}', param.name);
    customers.add(created);
    return created;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Customer _customer(String id, String name) => Customer(
      id: id,
      code: 'CU$id',
      name: name,
      address: '',
      phone: '',
      email: '',
      status: 'ACTIVE',
      type: 'General',
    );

class _EnglishDelegate extends LocalizationsDelegate<Languages> {
  const _EnglishDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Languages> load(Locale locale) =>
      SynchronousFuture<Languages>(LanguageEn());

  @override
  bool shouldReload(LocalizationsDelegate<Languages> old) => false;
}

void main() {
  tearDown(() async => sl.reset());

  testWidgets(
      'on a wide screen a new customer is listed as soon as it is added',
      (tester) async {
    // Arrange: the wide layout, the list beside the add form
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _ServerRepository();
    sl.registerFactory(() => CustomersViewModel(customerRepo: repo));
    sl.registerFactory(() => CustomerViewModel(customerRepo: repo));
    sl.registerFactory(() => CustomerAddViewModel(customerRepo: repo));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [_EnglishDelegate()],
      home: Scaffold(body: CustomerPage(onBack: () {})),
    ));
    await tester.pump();
    expect(find.text('ลูกค้าเดิม'), findsOneWidget);

    // Act: add a customer through the form beside the list
    await tester.tap(find.text('เพิ่มลูกค้า'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'ชื่อลูกค้า'), 'ลูกค้าใหม่');
    await tester.tap(find.text('ยืนยัน'));
    await tester.pump();
    await tester.pump();

    // Assert
    expect(repo.customers, hasLength(2), reason: 'the add reached the server');
    expect(find.text('ลูกค้าใหม่'), findsOneWidget,
        reason: 'the list reloads when the add form reports success');
  });
}
