// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_status.dart';
import 'order_item_detail.dart';

class OrderDetail {
  final String id;
  final double total;
  final double totalCost;
  final double discount;
  final String type;
  final String code;
  final String customerCode;
  final String customerName;
  final String? patientId;
  final String? pharmacistName;
  final String? licenseNo;
  final String? prescriberName;
  final String? buyerName;
  final String? buyerIdCard;
  final String createdDate;
  final List<OrderItemDetail> items;

  /// pos-api's status of the bill; empty when it sent none.
  final String status;

  OrderDetail({
    required this.id,
    required this.createdDate,
    required this.items,
    required this.total,
    required this.totalCost,
    required this.discount,
    required this.type,
    required this.code,
    required this.customerCode,
    required this.customerName,
    this.patientId,
    this.pharmacistName,
    this.licenseNo,
    this.prescriberName,
    this.buyerName,
    this.buyerIdCard,
    this.status = '',
  });

  /// A cancelled bill stays viewable, marked, and cannot be deleted again.
  bool get isCancelled => status == orderStatusCancelled;

  /// Whether [line] is cancelled: by its own status, or because the whole
  /// bill is (older data cancelled a bill and left its lines as they were).
  bool isLineCancelled(OrderItemDetail line) => isCancelled || line.isCancelled;

  /// The lines that count in a total, a receipt or an export: none of a
  /// cancelled bill's, and of any other bill those not cancelled.
  List<OrderItemDetail> get countedLines =>
      isCancelled ? const [] : items.counted;

  String getCreatedDate() {
    final date = DateTime.parse(createdDate);
    final format = DateFormat("dd/MM/yyyy HH:mm");
    return format.format(date.toLocal());
  }

  String getDate() {
    final date = DateTime.parse(createdDate);
    final format = DateFormat("dd/MM/yyyy");
    return format.format(date.toLocal());
  }
}
