// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/widgets/status_badge.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:pos/domain/model/order/order_item_detail.dart';
import 'package:pos/presentation/order/bill_summary.dart';
import 'package:pos/presentation/order/cancelled_mark.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/core/menu_entry.dart';
import 'package:pos/presentation/core/readable_tile.dart';

/// One line of a bill: its quantity as a leading `2×` (with its oversold
/// and returned marks), its product across the row (two lines at most),
/// what was paid at the end, and for an admin its cost and profit and one
/// menu of the return, history and delete actions. A cancelled line, or
/// any line of a cancelled bill, is still shown, marked [cancelledLabel],
/// its amount struck through, and offers no action.
class OrderLineTile extends StatelessWidget {
  final OrderItemDetail line;

  /// The name of the unit the line was sold in; empty while it is not known.
  final String unitName;

  /// Whether the line's bill is cancelled: then the line is too, whatever
  /// its own status says.
  final bool billCancelled;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onHistory;
  final VoidCallback onReturn;

  const OrderLineTile({
    super.key,
    required this.line,
    this.unitName = '',
    this.billCancelled = false,
    required this.isAdmin,
    required this.onTap,
    required this.onDelete,
    required this.onHistory,
    required this.onReturn,
  });

  static final _format = NumberFormat("#,##0.00", "en_US");

  bool get _cancelled => billCancelled || line.isCancelled;

  /// The least room the product's name keeps beside the amount; below it
  /// the amount moves under the name.
  static const _minNameWidth = 140.0;

  /// The row's own room besides the name and the amount: ListTile's side
  /// padding and gaps, the quantity column and the menu button.
  static const _rowFixedWidth = 16.0 * 2 + 16 + 56 + 16 + 48;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final amount = _buildAmount(context);
      final narrow =
          _nameRoom(context, amount, constraints.maxWidth) < _minNameWidth;
      // The quantity's column is a ListTile's leading, at most 56 high: it
      // holds one mark under the quantity, never two.
      final marksBeside = !narrow && _marks(context).length <= 1;
      return ReadableTile(
        label: _label(),
        leading: ExcludeSemantics(
            child: _buildQuantity(context, withMarks: marksBeside)),
        title: Text(line.product?.name ?? "",
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!narrow) ExcludeSemantics(child: amount),
            if (isAdmin && !_cancelled) _buildMenu(context),
          ],
        ),
        subtitle: _buildSubtitle(context,
            narrow: narrow, withMarks: !marksBeside, amount: amount),
        onTap: onTap,
      );
    });
  }

  Text _buildAmount(BuildContext context) => Text(_format.format(line.paid()),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
      ).merge(amountStyle(cancelled: _cancelled)));

  /// What a row [width] wide leaves the name with [amount] in the trailing.
  double _nameRoom(BuildContext context, Text amount, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(text: amount.data, style: amount.style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final amountWidth = painter.width;
    painter.dispose();
    return width - _rowFixedWidth - amountWidth - scaler.scale(16) + 16;
  }

  /// What the line reads, in the order a sighted user reads it: quantity
  /// and its marks, product, cancelled mark, cost and profit, amount.
  String _label() => [
        '${line.quantity}x',
        if (line.oversoldQty > 0) _oversold,
        if (line.returnedQty > 0) _returned,
        line.product?.name ?? '',
        if (_cancelled) cancelledLabel,
        if (isAdmin) _costAndProfit,
        '฿${_format.format(line.paid())}',
      ].join(' ').replaceAll(RegExp(r' {2,}'), ' ');

  String get _oversold => 'เกิน ${line.oversoldQty}';

  String get _returned => 'คืน ${line.returnedQty}';

  String get _costAndProfit => costAndProfitText(
      cost: line.costPrice, profit: line.paid() - line.costPrice);

  /// The cancelled mark sits here, not by the quantity, so that a line
  /// with its oversold or returned marks still fits its row.
  /// On a [narrow] row the [amount] heads it, on its own line under the
  /// name; the oversold and returned marks follow [withMarks].
  Widget? _buildSubtitle(BuildContext context,
      {required bool narrow, required bool withMarks, required Text amount}) {
    final marks = withMarks ? _marks(context) : const <Widget>[];
    if (!isAdmin && !_cancelled && !narrow && marks.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (narrow) amount,
        if (marks.isNotEmpty) Wrap(spacing: 4, runSpacing: 4, children: marks),
        if (_cancelled) const CancelledBadge(),
        if (isAdmin)
          Text(_costAndProfit,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.of(context).textSecondary)),
      ],
    );
  }

  /// The line's actions behind one menu, named for the line: a line is
  /// told apart from another of the same product by its quantity, unit and
  /// amount, as the cart names its lines. Each item is named in full the
  /// same way; delete is red, apart from the rest.
  Widget _buildMenu(BuildContext context) {
    final names = Languages.of(context);
    final product = [
      '${line.quantity}x',
      line.product?.name ?? '',
      if (unitName.isNotEmpty) unitName,
      '฿${_format.format(line.paid())}',
    ].join(' ');
    final error = Theme.of(context).colorScheme.error;
    return PopupMenuButton<VoidCallback>(
      tooltip: names.billLineCommands(product),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        if (line.quantity - line.returnedQty > 0)
          _item(Icons.keyboard_return, names.billLineReturn,
              names.returnBillLine(product), onReturn),
        _item(Icons.history, names.billLineSales,
            names.billLineHistory(product), onHistory),
        const PopupMenuDivider(),
        _item(Icons.delete, names.billLineDelete, names.deleteBillLine(product),
            onDelete,
            color: error),
      ],
    );
  }

  /// A menu item showing [text], named [name] in full for a screen reader.
  PopupMenuItem<VoidCallback> _item(
          IconData icon, String text, String name, VoidCallback action,
          {Color? color}) =>
      commandMenuItem(
          value: action, icon: icon, text: text, name: name, color: color);

  /// The quantity, `2×`, with its oversold and returned marks under it
  /// [withMarks].
  Widget _buildQuantity(BuildContext context, {required bool withMarks}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('${line.quantity}×',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (withMarks) ..._marks(context),
      ],
    );
  }

  /// The oversold and returned marks the line has.
  List<Widget> _marks(BuildContext context) => [
        if (line.oversoldQty > 0)
          StatusBadge(label: _oversold, color: Colors.orange),
        if (line.returnedQty > 0)
          StatusBadge(
              label: _returned, color: AppColors.of(context).textSecondary),
      ];
}
