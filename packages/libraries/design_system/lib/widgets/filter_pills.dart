// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/radius.dart';
import 'package:design_system/theme/spacing.dart';
import 'package:design_system/widgets/app_tag.dart';

/// One choice of a [FilterPills] row.
@immutable
class FilterPill<T> {
  final T value;
  final String label;

  /// How many rows the choice holds, shown after the label.
  final int? count;

  /// The fill of the pill while it is not selected.
  final AppTagTone? tone;

  const FilterPill({
    required this.value,
    required this.label,
    this.count,
    this.tone,
  });

  String get text => count == null ? label : '$label $count';
}

/// A row of choices, one of them selected: the filled one.
class FilterPills<T> extends StatelessWidget {
  static const double _gap = AppSpacing.sm;

  final List<FilterPill<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;

  /// One row that scrolls sideways, instead of wrapping onto more rows.
  final bool scrollable;

  const FilterPills({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final pills = [
      for (final item in items)
        _Pill(
          text: item.text,
          tone: item.tone ?? AppTagTone.neutral,
          selected: item.value == selected,
          onTap: () => onSelected(item.value),
        ),
    ];
    if (!scrollable) return Wrap(spacing: _gap, children: pills);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, pill) in pills.indexed) ...[
            if (index > 0) const SizedBox(width: _gap),
            pill,
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  static const double _height = 28;

  final String text;
  final AppTagTone tone;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.text,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tones = toneColors(colors, tone);
    final fill = selected ? colors.primaryFill : tones.fill;
    final foreground = selected ? colors.onPrimaryFill : tones.text;
    final outlined = !selected && tone == AppTagTone.neutral;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        // The pill is drawn smaller than the box that takes the tap.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: outlined ? Border.all(color: colors.border) : null,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _height),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: foreground),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
