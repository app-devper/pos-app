// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:pos/domain/model/order/order_detail.dart';
import 'package:pos/presentation/constants.dart';
import 'package:pos/presentation/order/cancelled_mark.dart';
import 'package:pos/localizations/language/languages.dart';

/// The top of a bill: its number and time, and a cancelled bill's
/// [cancelledLabel] mark.
class OrderDetailHeader extends StatelessWidget {
  final OrderDetail? bill;

  const OrderDetailHeader({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50 + defaultPagePadding * 2,
      padding: const EdgeInsets.all(defaultPagePadding),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Flexible(
            child:
                Text("${bill?.code ?? ""} ${(bill?.getCreatedDate() ?? "-")}"),
          ),
          if (bill?.isCancelled ?? false) ...[
            const SizedBox(width: 8),
            const CancelledBadge(),
          ],
        ],
      ),
    );
  }
}

/// The bill's app bar actions: the receipt for everyone; for an admin also
/// sync, the returns history and, unless the bill is already cancelled,
/// delete.
class OrderDetailActions extends StatelessWidget {
  final OrderDetail? bill;
  final bool isAdmin;
  final VoidCallback onPrint;
  final VoidCallback onSync;
  final VoidCallback onReturns;
  final VoidCallback onDelete;

  const OrderDetailActions({
    super.key,
    required this.bill,
    required this.isAdmin,
    required this.onPrint,
    required this.onSync,
    required this.onReturns,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final names = Languages.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.picture_as_pdf, names.billReceipt, onPrint),
        if (isAdmin) ...[
          _button(Icons.sync, names.billReload, onSync),
          _button(Icons.assignment_return, names.billReturns, onReturns),
          if (!(bill?.isCancelled ?? false))
            _button(Icons.delete, names.billDelete, onDelete),
        ],
      ],
    );
  }

  Widget _button(IconData icon, String tooltip, VoidCallback onPressed) =>
      IconButton(
        tooltip: tooltip,
        splashRadius: 20,
        onPressed: onPressed,
        icon: Icon(icon),
      );
}
