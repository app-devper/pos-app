// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/text_styles.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';

// Project imports:
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/home/main/quick_cash.dart';

/// The space between two chips, across and down.
const _chipSpacing = 8.0;

/// The smallest a chip is, a finger's target high.
const _chipMinSize = Size(56, 48);

/// The payment dialog's quick-cash chips for [total] (฿100 …), wrapping to a
/// second row rather than overflowing — or, [singleRow], all on one row,
/// each as narrow as it must be (its amount shrunk to fit), where a second
/// row would push the keypad off the screen. A tap passes its whole-baht
/// amount to [onSelected].
class QuickCashChips extends StatelessWidget {
  final double total;
  final ValueChanged<double> onSelected;
  final bool singleRow;

  const QuickCashChips({
    super.key,
    required this.total,
    required this.onSelected,
    this.singleRow = false,
  });

  @override
  Widget build(BuildContext context) {
    final amounts = quickCashAmounts(total);
    if (amounts.isEmpty) return const SizedBox.shrink();
    if (singleRow) {
      return Row(
        spacing: _chipSpacing,
        children: [
          for (final amount in amounts) Flexible(child: _chip(context, amount)),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: _chipSpacing,
        runSpacing: _chipSpacing,
        children: [
          for (final amount in amounts) _chip(context, amount),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, double amount) {
    final label = '฿${formatDecimal(amount)}';
    return OutlinedButton(
      onPressed: () => onSelected(amount),
      style: OutlinedButton.styleFrom(
        minimumSize: _chipMinSize,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const StadiumBorder(),
      ),
      child: Semantics(
        label: Languages.of(context).receiveCash(label),
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppText.money(
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
