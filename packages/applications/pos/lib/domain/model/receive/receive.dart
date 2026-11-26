// Package imports:
import 'package:pos/domain/model/receive/receive_item.dart';

// Project imports:
import 'package:pos/domain/model/supplier/supplier.dart';

/// pos-api's status of a deleted draft receipt: it is cancelled, not
/// deleted, and still returned by `GET /receives`.
const receiveStatusCancelled = 'CANCELLED';

class Receive {
  final String id;
  final String supplierId;
  final String code;
  final String reference;
  final double totalCost;
  final String createdDate;
  final String status;
  final List<ReceiveItem> items;
  bool get isImported => status == 'IMPORTED';

  /// A deleted draft: not listed.
  bool get isCancelled => status == receiveStatusCancelled;
  Supplier? supplier;

  Receive({
    required this.id,
    required this.supplierId,
    required this.code,
    required this.reference,
    required this.totalCost,
    required this.createdDate,
    this.status = 'ACTIVE',
    this.items = const [],
    this.supplier,
  });
}
