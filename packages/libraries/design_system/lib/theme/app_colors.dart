// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/color.dart';

/// Semantic colours that differ between light and dark.
///
/// [CustomColor] stays the home of brand and status colours, which read the
/// same either way. Anything that depends on the surface underneath it —
/// backgrounds, text, borders — belongs here so widgets resolve it from the
/// theme instead of hardcoding a light value.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Page background, behind everything else.
  final Color surface;

  /// Cards, sheets and bars that sit on top of [surface].
  final Color surfaceRaised;

  /// Fill for inputs and other sunken areas.
  final Color surfaceSunken;

  /// Hairlines and outlines.
  final Color border;

  /// Body copy and headings.
  final Color textPrimary;

  /// Supporting copy: subtitles, metadata, disabled labels.
  final Color textSecondary;

  /// Placeholder text inside empty inputs.
  final Color textHint;

  /// Sidebar panel, a touch off [surface] so the frame reads as its own area.
  final Color sidebarSurface;

  /// Fill behind the selected sidebar entry.
  final Color sidebarSelected;

  /// Sidebar labels and icons.
  final Color sidebarForeground;

  /// Fill of the one primary action on a screen, and of a selected pill.
  final Color primaryFill;

  /// Text and icons on [primaryFill].
  final Color onPrimaryFill;

  /// Fill behind a warning: low stock.
  final Color statusWarningFill;

  /// Text on [statusWarningFill].
  final Color statusWarningText;

  /// Fill behind a danger status: cancelled, dangerous drug.
  final Color statusDangerFill;

  /// Text on [statusDangerFill].
  final Color statusDangerText;

  /// Fill behind a success status.
  final Color statusSuccessFill;

  /// Text on [statusSuccessFill]; also change due.
  final Color statusSuccessText;

  const AppColors({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.sidebarSurface,
    required this.sidebarSelected,
    required this.sidebarForeground,
    required this.primaryFill,
    required this.onPrimaryFill,
    required this.statusWarningFill,
    required this.statusWarningText,
    required this.statusDangerFill,
    required this.statusDangerText,
    required this.statusSuccessFill,
    required this.statusSuccessText,
  });

  static const light = AppColors(
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF7F7F5),
    border: Color(0xFFE8E8E6),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF6F6F6C),
    textHint: Color(0x99000000),
    sidebarSurface: Color(0xFFF9F9F9),
    sidebarSelected: Color(0xFFECECEC),
    sidebarForeground: Color(0xFF303030),
    primaryFill: Color(0xFF111111),
    onPrimaryFill: Color(0xFFFFFFFF),
    statusWarningFill: Color(0xFFFAEEDA),
    statusWarningText: Color(0xFF633806),
    statusDangerFill: Color(0xFFFCEBEB),
    statusDangerText: Color(0xFF791F1F),
    statusSuccessFill: Color(0xFFE1F5EE),
    statusSuccessText: Color(0xFF085041),
  );

  static const dark = AppColors(
    surface: Color(0xFF212121),
    surfaceRaised: Color(0xFF292929),
    surfaceSunken: Color(0xFF303030),
    border: Color(0xFF424242),
    textPrimary: Color(0xFFECECEC),
    textSecondary: Color(0xFFB4B4B4),
    textHint: Color(0x99FFFFFF),
    sidebarSurface: Color(0xFF171717),
    sidebarSelected: Color(0xFF303030),
    sidebarForeground: Color(0xFFECECEC),
    primaryFill: Color(0xFFECECEC),
    onPrimaryFill: Color(0xFF111111),
    statusWarningFill: Color(0xFF412402),
    statusWarningText: Color(0xFFFAC775),
    statusDangerFill: Color(0xFF501313),
    statusDangerText: Color(0xFFF7C1C1),
    statusSuccessFill: Color(0xFF04342C),
    statusSuccessText: Color(0xFF9FE1CB),
  );

  /// Falls back to the light set so a widget still renders if a host forgot
  /// to register the extension.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? sidebarSurface,
    Color? sidebarSelected,
    Color? sidebarForeground,
    Color? primaryFill,
    Color? onPrimaryFill,
    Color? statusWarningFill,
    Color? statusWarningText,
    Color? statusDangerFill,
    Color? statusDangerText,
    Color? statusSuccessFill,
    Color? statusSuccessText,
  }) {
    return AppColors(
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      sidebarSurface: sidebarSurface ?? this.sidebarSurface,
      sidebarSelected: sidebarSelected ?? this.sidebarSelected,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      primaryFill: primaryFill ?? this.primaryFill,
      onPrimaryFill: onPrimaryFill ?? this.onPrimaryFill,
      statusWarningFill: statusWarningFill ?? this.statusWarningFill,
      statusWarningText: statusWarningText ?? this.statusWarningText,
      statusDangerFill: statusDangerFill ?? this.statusDangerFill,
      statusDangerText: statusDangerText ?? this.statusDangerText,
      statusSuccessFill: statusSuccessFill ?? this.statusSuccessFill,
      statusSuccessText: statusSuccessText ?? this.statusSuccessText,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      sidebarSurface: Color.lerp(sidebarSurface, other.sidebarSurface, t)!,
      sidebarSelected: Color.lerp(sidebarSelected, other.sidebarSelected, t)!,
      sidebarForeground: Color.lerp(
        sidebarForeground,
        other.sidebarForeground,
        t,
      )!,
      primaryFill: Color.lerp(primaryFill, other.primaryFill, t)!,
      onPrimaryFill: Color.lerp(onPrimaryFill, other.onPrimaryFill, t)!,
      statusWarningFill: Color.lerp(statusWarningFill, other.statusWarningFill, t)!,
      statusWarningText: Color.lerp(statusWarningText, other.statusWarningText, t)!,
      statusDangerFill: Color.lerp(statusDangerFill, other.statusDangerFill, t)!,
      statusDangerText: Color.lerp(statusDangerText, other.statusDangerText, t)!,
      statusSuccessFill: Color.lerp(statusSuccessFill, other.statusSuccessFill, t)!,
      statusSuccessText: Color.lerp(statusSuccessText, other.statusSuccessText, t)!,
    );
  }
}

/// Brand and status colours, unchanged between the two themes.
extension AppStatusColors on AppColors {
  Color get primary => CustomColor.primary;
  Color get success => CustomColor.success;
  Color get warning => CustomColor.warning;
  Color get error => CustomColor.error;
  Color get info => CustomColor.info;
}
