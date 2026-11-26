// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/domain/model/receipt/receipt.dart';
import 'package:pos/domain/model/supplier/supplier.dart';

/// The receipt printed for [order]: a cancelled line, or any line of a
/// cancelled bill, was not paid for, so it is not printed and not in the
/// receipt's total (which the PDF sums from these lines).
Receipt billReceipt({
  required OrderDetail order,
  required Supplier supplier,
  required Customer customer,
}) {
  return Receipt(
    supplier: supplier,
    customer: customer,
    info: ReceiptInfo(date: order.getDate(), number: order.code),
    items: order.countedLines,
  );
}
