// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/radius.dart';
import 'package:design_system/widgets/app_tag.dart';

/// One figure with its label: how many products, how much stock.
class FigureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppTagTone tone;

  const FigureTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tone = AppTagTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tones = toneColors(colors, tone);
    final neutral = tone == AppTagTone.neutral;
    final labelColor = neutral ? colors.textSecondary : tones.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tones.fill,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: neutral ? Border.all(color: colors.border) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: labelColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: labelColor),
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tones.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
