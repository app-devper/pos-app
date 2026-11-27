import 'dart:math' as math;

import 'package:design_system/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a), lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const minimumContrast = 4.5;

void main() {
  for (final entry in {'light': AppColors.light, 'dark': AppColors.dark}.entries) {
    final c = entry.value;
    final pairs = <String, (Color, Color)>{
      'text on the primary fill': (c.onPrimaryFill, c.primaryFill),
      'primary text on the page': (c.textPrimary, c.surface),
      'primary text on a sunken area': (c.textPrimary, c.surfaceSunken),
      'supporting text on the page': (c.textSecondary, c.surface),
      'supporting text on a sunken area': (c.textSecondary, c.surfaceSunken),
      'warning tag': (c.statusWarningText, c.statusWarningFill),
      'danger tag': (c.statusDangerText, c.statusDangerFill),
      'success tag': (c.statusSuccessText, c.statusSuccessFill),
    };
    for (final pair in pairs.entries) {
      test('${entry.key}: ${pair.key} reads at 4.5:1 or better', () {
        final (foreground, background) = pair.value;
        expect(contrast(foreground, background),
            greaterThanOrEqualTo(minimumContrast));
      });
    }
  }

  test('the light tokens are the redesign\'s', () {
    expect(AppColors.light.primaryFill, const Color(0xFF111111));
    expect(AppColors.light.textPrimary, const Color(0xFF111111));
    expect(AppColors.light.textSecondary, const Color(0xFF6F6F6C));
    expect(AppColors.light.border, const Color(0xFFE8E8E6));
    expect(AppColors.light.surfaceSunken, const Color(0xFFF7F7F5));
  });

  test('copyWith and lerp keep the new roles', () {
    final changed = AppColors.light.copyWith(primaryFill: Colors.red);
    expect(changed.primaryFill, Colors.red);
    expect(changed.statusWarningFill, AppColors.light.statusWarningFill);
    final end = AppColors.light.lerp(AppColors.dark, 1);
    expect(end.primaryFill, AppColors.dark.primaryFill);
    expect(end.statusSuccessText, AppColors.dark.statusSuccessText);
  });
}
