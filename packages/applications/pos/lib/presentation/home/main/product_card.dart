// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/text_styles.dart';
import 'package:design_system/widgets/app_card.dart';
import 'package:design_system/widgets/app_tag.dart';

// Project imports:
import 'package:pos/domain/model/core/core.dart';
import 'package:pos/domain/model/product/product.dart';

/// A product on the selling grid: its category, name, price and what is
/// left, and what a tap does. The whole card is the button that adds it.
///
/// [inCart] is how many of it the open cart holds. [compact] is the phone's
/// card: a plus instead of the add label.
class ProductCard extends StatelessWidget {
  /// The grid's row heights; both leave room for two lines of name at a
  /// large text size.
  static const double height = 200;
  static const double compactHeight = 160;

  static const double _cueHeight = 32;
  static const double _cueRadius = 8;

  final ProductUnitItem item;
  final int inCart;
  final VoidCallback onAdd;
  final bool compact;

  const ProductCard({
    super.key,
    required this.item,
    required this.inCart,
    required this.onAdd,
    this.compact = false,
  });

  int get _quantity => item.getQuantity();
  bool get _available => _quantity > 0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // One button, named name first: an end-to-end flow finds the card by a
    // label that begins with the product's name.
    return Semantics(
      container: true,
      button: true,
      label: _semanticLabel,
      onTap: onAdd,
      excludeSemantics: true,
      child: AppCard(
        onTap: onAdd,
        muted: !_available,
        selected: inCart > 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppTag(label: findCategoryType(item.category).name),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: _available ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            const Spacer(),
            _stockLeft(context, colors),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: _price(colors)),
                if (compact) _compactCue(colors),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              _cue(colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _price(AppColors colors) {
    final price = item.getPrice(priceTypeStock).price;
    return Text(
      '฿${formatDouble(price)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.money(TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _available ? colors.textPrimary : colors.textSecondary,
      )),
    );
  }

  /// What is left, in the warning tone once it is at the shop's low level.
  Widget _stockLeft(BuildContext context, AppColors colors) {
    final low = item.isLowStock;
    final color = !_available
        ? Theme.of(context).colorScheme.error
        : low
            ? colors.statusWarningText
            : colors.textSecondary;
    return Row(
      children: [
        if (low) ...[
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 2),
        ],
        Flexible(
          child: Text(
            _stockText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }

  String get _stockText =>
      _available ? 'คงเหลือ $_quantity ${item.unit.unit}' : 'สินค้าหมด';

  String get _semanticLabel => [
        item.name,
        findCategoryType(item.category).name,
        '฿${formatDouble(item.getPrice(priceTypeStock).price)}',
        _stockText,
        _cueLabel,
      ].join('\n');

  String get _cueLabel {
    if (inCart > 0) return 'ในตะกร้า $inCart';
    return _available ? 'เพิ่มลงตะกร้า' : 'หมด';
  }

  /// What a tap on the card does, drawn as the card's own outline button.
  Widget _cue(AppColors colors) {
    final inCartNow = inCart > 0;
    final foreground = _available ? colors.textPrimary : colors.textSecondary;
    return Container(
      height: _cueHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: inCartNow || !_available ? colors.surfaceSunken : null,
        borderRadius: BorderRadius.circular(_cueRadius),
        border: Border.all(
          color: inCartNow ? colors.textPrimary : colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_available && !inCartNow) ...[
            Icon(Icons.add, size: 16, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              _cueLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  /// The phone's cue: a plus, or how many the cart holds.
  Widget _compactCue(AppColors colors) {
    if (!_available) {
      return Text(
        'หมด',
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      );
    }
    final inCartNow = inCart > 0;
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: inCartNow ? colors.primaryFill : null,
        borderRadius: BorderRadius.circular(_cueRadius),
        border: inCartNow ? null : Border.all(color: colors.border),
      ),
      child: inCartNow
          ? Text(
              '$inCart',
              style: TextStyle(fontSize: 13, color: colors.onPrimaryFill),
            )
          : Icon(Icons.add, size: 16, color: colors.textPrimary),
    );
  }
}
