// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/domain/model/supplier/supplier.dart';
import 'package:pos/presentation/order/detail/bill_receipt.dart';

OrderItemDetail _line(String id, {required double price, String status = ''}) =>
    OrderItemDetail(
      id: id,
      product: null,
      quantity: 1,
      price: price,
      costPrice: 0,
      discount: 0,
      createdDate: '2026-11-26T10:00:00Z',
      order: null,
      status: status,
    );

OrderDetail _bill(List<OrderItemDetail> items) => OrderDetail(
      id: 'order-1',
      createdDate: '2026-11-26T10:00:00Z',
      items: items,
      total: 30,
      totalCost: 0,
      discount: 0,
      type: 'Cash',
      code: 'OD_1',
      customerCode: '',
      customerName: '',
    );

final _supplier =
    Supplier(id: 's', name: 'ร้าน', address: '', phone: '', taxId: '');
final _customer = Customer(
    id: '',
    code: '',
    name: 'ลูกค้า',
    address: '',
    phone: '',
    email: '',
    status: '',
    type: '');

void main() {
  test('a bill\'s receipt prints only the lines that are not cancelled', () {
    // Arrange
    final bill = _bill([
      _line('sold', price: 30, status: 'CONFIRMED'),
      _line('cancelled', price: 20, status: 'CANCELLED'),
    ]);

    // Act
    final receipt =
        billReceipt(order: bill, supplier: _supplier, customer: _customer);

    // Assert
    expect(receipt.items.map((line) => line.id), ['sold']);
    expect(receipt.info.number, 'OD_1');
    expect(receipt.info.date, '26/11/2026');
  });
}
