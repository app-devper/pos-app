// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/radius.dart';

/// The product's card: a hairline box, no shadow.
///
/// [selected] outlines it in the text colour; [muted] sets it on the sunken
/// fill, for something present but not available. With [onTap] the whole
/// card is one button.
class AppCard extends StatelessWidget {
  static const EdgeInsets defaultPadding = EdgeInsets.all(12);

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool selected;
  final bool muted;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadius.card);
    final content = Padding(padding: padding ?? defaultPadding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: muted ? colors.surfaceSunken : colors.surfaceRaised,
        borderRadius: radius,
        border: Border.all(
          color: selected ? colors.textPrimary : colors.border,
        ),
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: Semantics(
                button: true,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: content,
                ),
              ),
            ),
    );
  }
}
