// Package imports:
import 'package:intl/intl.dart';

class StockCountItem {
  String productId;
  String stockId;
  int systemQuantity;
  int countedQuantity;
  int delta;

  /// What pos-api names the line by when it is read: empty for what it no
  /// longer knows, or from a pos-api that does not send them.
  String productName;
  String unit;
  String lotNumber;

  StockCountItem({
    required this.productId,
    required this.stockId,
    required this.systemQuantity,
    required this.countedQuantity,
    required this.delta,
    this.productName = '',
    this.unit = '',
    this.lotNumber = '',
  });
}

class StockCount {
  String id;
  String countNo;
  String note;
  List<StockCountItem> items;
  String createdDate;

  StockCount({
    required this.id,
    required this.countNo,
    required this.note,
    required this.items,
    required this.createdDate,
  });

  String getCreatedDate() {
    final date = DateTime.parse(createdDate);
    final format = DateFormat("dd/MM/yyyy HH:mm");
    return format.format(date.toLocal());
  }
}
