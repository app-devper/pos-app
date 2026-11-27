// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/radius.dart';

/// What a tag, pill or figure says about its subject. Colour carries status
/// only; everything else is [neutral].
enum AppTagTone { neutral, warning, danger, success }

/// The fill and text colour of a [tone] in [colors].
({Color fill, Color text}) toneColors(AppColors colors, AppTagTone tone) {
  return switch (tone) {
    AppTagTone.neutral => (fill: colors.surfaceRaised, text: colors.textPrimary),
    AppTagTone.warning => (
        fill: colors.statusWarningFill,
        text: colors.statusWarningText,
      ),
    AppTagTone.danger => (
        fill: colors.statusDangerFill,
        text: colors.statusDangerText,
      ),
    AppTagTone.success => (
        fill: colors.statusSuccessFill,
        text: colors.statusSuccessText,
      ),
  };
}

/// A small label for a category or a status.
class AppTag extends StatelessWidget {
  static const double fontSize = 12;

  final String label;
  final AppTagTone tone;

  const AppTag({super.key, required this.label, this.tone = AppTagTone.neutral});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tones = toneColors(colors, tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tones.fill,
        borderRadius: BorderRadius.circular(AppRadius.tag),
        border: tone == AppTagTone.neutral
            ? Border.all(color: colors.border)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: tones.text,
          ),
        ),
      ),
    );
  }
}
