// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:design_system/theme/motion.dart';

/// The shell's content area: a new [section] cross-fades over the one
/// before (out within [AppMotion.short], in within [AppMotion.medium]),
/// with no slide and no change of size, and at once under reduced motion.
///
/// Each section is built afresh, as before the fade: the one going out
/// only stays on screen while it fades, and takes no taps, focus or screen
/// reader meanwhile.
class SectionSwitcher extends StatelessWidget {
  /// Which section [child] shows; a different one starts the fade.
  final Object section;
  final Widget child;

  const SectionSwitcher({
    super.key,
    required this.section,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.medium),
      reverseDuration: AppMotion.of(context, AppMotion.short),
      switchInCurve: AppMotion.enterCurve,
      switchOutCurve: AppMotion.exitCurve,
      layoutBuilder: _stacked,
      transitionBuilder: (child, animation) => _OutgoingGuard(
        animation: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: KeyedSubtree(key: ValueKey(section), child: child),
    );
  }

  /// Both sections laid out as the content area itself, one over the
  /// other: nothing changes size while they fade.
  static Widget _stacked(Widget? current, List<Widget> previous) => Stack(
        fit: StackFit.passthrough,
        children: [...previous, if (current != null) current],
      );
}

/// Shuts [child] off from taps, focus and the screen reader once its
/// [animation] runs backwards, that is once its section is going out.
class _OutgoingGuard extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;

  const _OutgoingGuard({required this.animation, required this.child});

  @override
  State<_OutgoingGuard> createState() => _OutgoingGuardState();
}

class _OutgoingGuardState extends State<_OutgoingGuard> {
  bool get _isOutgoing => switch (widget.animation.status) {
        AnimationStatus.reverse || AnimationStatus.dismissed => true,
        AnimationStatus.forward || AnimationStatus.completed => false,
      };

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(_OutgoingGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation == widget.animation) return;
    oldWidget.animation.removeStatusListener(_onStatus);
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  void _onStatus(AnimationStatus _) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final outgoing = _isOutgoing;
    return IgnorePointer(
      ignoring: outgoing,
      child: ExcludeFocus(
        excluding: outgoing,
        child: ExcludeSemantics(excluding: outgoing, child: widget.child),
      ),
    );
  }
}
