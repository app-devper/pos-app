// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/color.dart';
import 'package:design_system/widgets/app_tag.dart';

/// A status drawn as an [AppTag]. [color] is the status colour callers have
/// always passed; it picks the tag's tone.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  static AppTagTone toneOf(Color color) {
    if (color == CustomColor.error) return AppTagTone.danger;
    if (color == CustomColor.warning) return AppTagTone.warning;
    if (color == CustomColor.success) return AppTagTone.success;
    return AppTagTone.neutral;
  }

  @override
  Widget build(BuildContext context) =>
      AppTag(label: label, tone: toneOf(color));
}
