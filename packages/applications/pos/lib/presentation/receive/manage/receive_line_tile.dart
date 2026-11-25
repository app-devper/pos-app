// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/receive/receive_item.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/core/readable_tile.dart';

/// One line of a goods receipt: its product, quantity, cost and line total,
/// and a delete button (a lock once the receipt is imported).
class ReceiveLineTile extends StatelessWidget {
  final ReceiveItem line;
  final bool imported;
  final VoidCallback onDelete;

  const ReceiveLineTile({
    super.key,
    required this.line,
    required this.imported,
    required this.onDelete,
  });

  static final _format = NumberFormat("#,##0.00", "en_US");

  @override
  Widget build(BuildContext context) {
    final product = line.product?.name ?? '-';
    final title = 'Name: $product';
    final subtitle =
        'Quantity: ${line.quantity} Cost: ${_format.format(line.costPrice)}';
    final total = _format.format(line.costPrice * line.quantity);
    return ReadableTile(
      label: '$title\n$subtitle\n$total',
      leading: SizedBox(
        width: 50,
        height: 50,
        // A button node of its own, beside the line's text.
        child: Semantics(
          container: true,
          button: true,
          label: imported
              ? Languages.of(context).importedReceiveLine(product)
              : Languages.of(context).deleteReceiveLine(product),
          child: InkWell(
            onTap: onDelete,
            child: Icon(imported ? Icons.lock : Icons.delete),
          ),
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: ExcludeSemantics(child: Text(total)),
    );
  }
}
