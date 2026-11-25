// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/presentation/receive/manage/receive_supplier_picker.dart';
import '../../../support/app_fonts.dart';

final _supplier = Supplier(
  id: 's1',
  name: 'บริษัท ยาดี ซัพพลาย จำกัด',
  address: '',
  phone: '',
  taxId: '',
);

Widget _host(Supplier? value) => MaterialApp(
      theme: CustomTheme.mainTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ReceiveSupplierPicker(
              suppliers: [_supplier],
              value: value,
              onChanged: (_) {},
              onAdd: () {},
              addLabel: 'เพิ่มร้านขายสินค้า',
            ),
          ]),
        ),
      ),
    );

void main() {
  setUpAll(loadAppFonts);

  for (final size in [phoneSize, desktopSize]) {
    testWidgets('the chosen supplier is shown whole, without overflow, $size',
        (tester) async {
      // Arrange
      useViewSize(tester, size);

      // Act
      await tester.pumpWidget(_host(_supplier));
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
      expectInside(tester, find.text(_supplier.name),
          find.byType(DropdownButtonFormField<Supplier>));
      // The label floats on the outline's top edge, inside the page.
      expectInside(tester, find.text('ร้านขายสินค้า'), find.byType(Scaffold));
    });
  }
}
