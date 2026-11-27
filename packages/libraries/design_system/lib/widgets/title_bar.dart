// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/app_colors.dart';

class TitleBar extends StatelessWidget {
  final String title;
  final Function onBack;
  final String? action;
  final Function? onAction;

  const TitleBar({
    super.key,
    required this.title,
    this.action,
    required this.onBack,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    Widget actionButton(String label, VoidCallback? onPressed) {
      return SizedBox(
        width: 80,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(80, 48),
            foregroundColor: colors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return Row(
      children: [
        actionButton('ปิด', () => onBack()),
        Expanded(
          // The tooltip shows a title cut short; the title is read once, as
          // a header node of its own (on the web a text merged into a node
          // with children is not written into the page).
          child: Tooltip(
            message: title,
            excludeFromSemantics: true,
            child: Semantics(
              container: true,
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        if (action != null)
          actionButton(action!, onAction == null ? null : () => onAction!())
        else
          const SizedBox(width: 80),
      ],
    );
  }
}
