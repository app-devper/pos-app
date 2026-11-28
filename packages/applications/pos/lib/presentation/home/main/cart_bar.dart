// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/radius.dart';
import 'package:design_system/theme/text_styles.dart';

// Project imports:
import 'package:pos/localizations/language/languages.dart';

/// The phone's open cart, along the foot of the products: which cart, and
/// what it holds. A tap opens the cart.
class CartBar extends StatelessWidget {
  static const double _height = 56;

  /// The open cart, counted from 1.
  final int cartNumber;
  final int lineCount;
  final double total;
  final VoidCallback onOpen;

  const CartBar({
    super.key,
    required this.cartNumber,
    required this.lineCount,
    required this.total,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = Languages.of(context);
    final title = '${strings.cartTitle} #$cartNumber';
    final empty = lineCount == 0;
    final detail = empty
        ? strings.cartEmpty
        : '${strings.cartLines(lineCount)} ฿${formatDouble(total)}';
    // Filled once it holds something: then it is the way on to payment.
    final fill = empty ? colors.surfaceSunken : colors.primaryFill;
    final foreground = empty ? colors.textPrimary : colors.onPrimaryFill;
    // One button named by what it holds, which a screen reader can press.
    return Semantics(
      container: true,
      button: true,
      label: '$title\n$detail',
      onTap: onOpen,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Material(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: onOpen,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _height),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart_outlined, color: foreground),
                    const SizedBox(width: 12),
                    // The cart's name over what it holds; at a large text
                    // size the name shrinks to fit rather than being cut.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              title,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: foreground,
                              ),
                            ),
                          ),
                          Text(
                            empty
                                ? strings.cartEmpty
                                : strings.cartLines(lineCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: foreground),
                          ),
                        ],
                      ),
                    ),
                    if (!empty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '฿${formatDouble(total)}',
                        style: AppText.money(TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: foreground,
                        )),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: foreground),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
