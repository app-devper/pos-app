// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/radius.dart';
import 'package:design_system/widgets/app_tag.dart';

/// A status label.
///
/// [StatusBadge.tone] is the redesign's form: an [AppTag]. The form that
/// takes a [color] keeps that colour, in the tag's shape, for callers that
/// tell things apart by colour (movement types, roles) until their screen
/// moves to tones.
class StatusBadge extends StatelessWidget {
  static const double _tintAlpha = 0.1;

  final String label;
  final Color? color;
  final AppTagTone? tone;

  const StatusBadge({super.key, required this.label, required Color this.color})
      : tone = null;

  const StatusBadge.tone({
    super.key,
    required this.label,
    required AppTagTone this.tone,
  }) : color = null;

  @override
  Widget build(BuildContext context) {
    final tone = this.tone;
    if (tone != null) return AppTag(label: label, tone: tone);
    final color = this.color!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: _tintAlpha),
        borderRadius: BorderRadius.circular(AppRadius.tag),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppTag.fontSize,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
