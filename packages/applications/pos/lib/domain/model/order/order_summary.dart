// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_status.dart';

class OrderSummary {
  final String id;
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
  final double total;
  final double totalCost;
  final double discount;
  final String type;

  /// pos-api's status of the bill; empty when it sent none.
  final String status;

  OrderSummary({
    required this.id,
    required this.code,
    required this.customerCode,
    required this.customerName,
    this.patientId,
    this.pharmacistName,
    this.licenseNo,
    this.prescriberName,
    this.buyerName,
    this.buyerIdCard,
    required this.createdDate,
    required this.total,
    required this.totalCost,
    required this.discount,
    required this.type,
    this.status = '',
  });

  /// A cancelled bill stays listed, marked, and counts in no total.
  bool get isCancelled => status == orderStatusCancelled;

  String getCreatedDate() {
    final date = DateTime.parse(createdDate);
    final format = DateFormat("dd/MM/yyyy HH:mm");
    return format.format(date.toLocal());
  }
}
