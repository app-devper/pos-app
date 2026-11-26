// Flutter imports:
import 'package:flutter/widgets.dart';

/// How long things move, and how: one set for every transition in the app.
abstract final class AppMotion {
  /// An exit, or a switch between the shell's sections fading out.
  static const short = Duration(milliseconds: 150);

  /// An enter: a pushed page or a section fading in.
  static const medium = Duration(milliseconds: 250);

  /// The curve of something coming in.
  static const enterCurve = Curves.easeOutCubic;

  /// The curve of something going out.
  static const exitCurve = Curves.easeInCubic;

  /// [duration], or none when the person asked for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
