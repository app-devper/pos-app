// Flutter imports:
import 'package:flutter/material.dart';

/// The product's text styles that carry a meaning of their own.
class AppText {
  const AppText._();

  /// The feature that draws every figure the same width.
  static const _tabularFigures = FontFeature.tabularFigures();

  /// An amount of money: [base] with its figures in even columns, so
  /// amounts in rows, totals and the payment boxes line up and do not
  /// shift as they change. A null [base] is the surrounding style.
  static TextStyle money(TextStyle? base) {
    final style = base ?? const TextStyle();
    final features = style.fontFeatures ?? const <FontFeature>[];
    if (features.contains(_tabularFigures)) return style;
    return style.copyWith(
      fontFeatures: List.unmodifiable([...features, _tabularFigures]),
    );
  }
}
