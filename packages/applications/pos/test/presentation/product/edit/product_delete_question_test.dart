// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/localizations/localizations_delegate.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/container.dart';
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';
import 'package:pos/domain/repositories/product_repository.dart';
import 'package:pos/presentation/product/edit/product_edit_page.dart';
import 'package:pos/presentation/product/edit/product_edit_view_model.dart';

class _Catalogue implements ProductRepository {
  final Product product;

  _Catalogue(this.product);

  @override
  Future<Product?> getLocalProductById(String productId) async => product;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Product _product({required int onHand}) => Product(
      id: 'p1',
      name: 'Paracetamol',
      unit: 'ชิ้น',
      status: productStatusActive,
      category: 'General',
      createdDate: '',
      units: [
        ProductUnit(
          id: 'u1',
          productId: 'p1',
          costPrice: 5,
          unit: 'ชิ้น',
          size: 1,
          barcode: '',
          volume: 0,
          volumeUnit: '',
        ),
      ],
      prices: const [],
      stocks: [
        if (onHand > 0)
          ProductStock(
            id: 's1',
            unitId: 'u1',
            productId: 'p1',
            receiveCode: '',
            sequence: 1,
            lotNumber: 'L1',
            costPrice: 5,
            price: 10,
            import: onHand,
            quantity: onHand,
            expireDate: '',
            importDate: '',
          ),
      ],
    );

Future<void> _askToDelete(WidgetTester tester, Product product) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  sl.registerFactory(
      () => ProductEditViewModel(productRepo: _Catalogue(product)));
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: [CommonLocalizationsDelegate()],
    home: Scaffold(
      body: ProductEditPage(
        product: product,
        onBack: () {},
        onEdit: () {},
        onRemove: () {},
      ),
    ),
  ));
  await tester.pumpAndSettle();
  final remove = find.text('ลบสินค้า');
  await tester.ensureVisible(remove);
  await tester.tap(remove);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async => sl.reset());

  testWidgets(
      'deleting a product that has stock says how much is left, and that '
      'every branch\'s stock goes', (tester) async {
    // Arrange / Act
    await _askToDelete(tester, _product(onHand: 10));

    // Assert
    expect(
        find.text('สินค้านี้มีสต็อกคงเหลือ 10 ชิ้น '
            'การลบจะปรับสต็อกของสินค้านี้เป็น 0 ในทุกสาขา ต้องการลบใช่หรือไม่?'),
        findsOneWidget);
  });

  testWidgets(
      'deleting a product with no stock here still says other branches\' '
      'stock goes', (tester) async {
    // Arrange / Act
    await _askToDelete(tester, _product(onHand: 0));

    // Assert
    expect(
        find.text('ต้องการลบสินค้าใช่หรือไม่? '
            'สต็อกของสินค้านี้ในสาขาอื่น (ถ้ามี) จะถูกปรับเป็น 0'),
        findsOneWidget);
  });
}
