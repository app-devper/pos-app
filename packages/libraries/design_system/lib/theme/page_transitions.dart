// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/motion.dart';

/// How a pushed page comes in on each platform: Android previews the page
/// underneath on a back swipe, iOS and macOS slide, the rest fade
/// forwards. On the web the browser owns the gestures, so every platform
/// fades forwards.
PageTransitionsTheme appPageTransitionsTheme({required bool isWeb}) {
  const fade = _AppFadeForwards();
  if (isWeb) {
    return PageTransitionsTheme(
      builders: {for (final platform in TargetPlatform.values) platform: fade},
    );
  }
  const slide = _AppCupertino();
  return const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _AppPredictiveBack(),
      TargetPlatform.iOS: slide,
      TargetPlatform.macOS: slide,
      TargetPlatform.windows: fade,
      TargetPlatform.linux: fade,
      TargetPlatform.fuchsia: fade,
    },
  );
}

/// The platform's own transition on the app's clock: in within
/// [AppMotion.medium], back within [AppMotion.short], and instant when the
/// person asked for reduced motion.
mixin _AppMotionTransition on PageTransitionsBuilder {
  /// The route reads its durations without a context, so reduced motion
  /// comes from the platform, where [MediaQuery] takes it from too.
  bool get _platformReducesMotion => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;

  @override
  Duration get transitionDuration =>
      _platformReducesMotion ? Duration.zero : AppMotion.medium;

  @override
  Duration get reverseTransitionDuration =>
      _platformReducesMotion ? Duration.zero : AppMotion.short;

  // Nullable as FadeForwardsPageTransitionsBuilder declares them; a page
  // route always passes both.
  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route == null || context == null) return child;
    // Reduced motion set below the platform (a MediaQuery of the app's
    // own): the page is drawn where it ends, the same widgets either way.
    final still = MediaQuery.disableAnimationsOf(context);
    return super.buildTransitions(
      route,
      context,
      still ? kAlwaysCompleteAnimation : animation,
      still ? kAlwaysDismissedAnimation : secondaryAnimation,
      child,
    );
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    final inner = super.delegatedTransition;
    if (inner == null) return null;
    return (context, animation, secondaryAnimation, allowSnapshotting, child) {
      final still = MediaQuery.disableAnimationsOf(context);
      return inner(
        context,
        animation,
        still ? kAlwaysDismissedAnimation : secondaryAnimation,
        allowSnapshotting,
        child,
      );
    };
  }
}

class _AppPredictiveBack extends PredictiveBackPageTransitionsBuilder
    with _AppMotionTransition {
  const _AppPredictiveBack();
}

class _AppCupertino extends CupertinoPageTransitionsBuilder
    with _AppMotionTransition {
  const _AppCupertino();
}

class _AppFadeForwards extends FadeForwardsPageTransitionsBuilder
    with _AppMotionTransition {
  const _AppFadeForwards();
}
